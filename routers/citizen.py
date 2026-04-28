from fastapi import APIRouter, HTTPException, status, Depends
from database import citizen_collection, citizen_query_collection, penalty_collection, site_collection, contractor_collection
from models.citizen import CitizenCreate, CitizenLogin, Citizen, CitizenQueryCreate, CitizenQuery
from models.token import Token
from utils.security import verify_password, get_password_hash, create_access_token
from utils.deps import get_current_citizen
from utils.notify import notify_complaint_received, notify_penalty_issued
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

router = APIRouter(prefix="/citizen", tags=["Citizen"])


class ComplaintResolveRequest(BaseModel):
    action: str  # "approve" or "reject"
    reason: Optional[str] = None
    penalty_amount: Optional[float] = None


@router.post("/signup", response_model=Citizen)
async def signup(user_data: CitizenCreate):
    existing_user = await citizen_collection.find_one({"username": user_data.username})
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    user_dict = user_data.model_dump()
    user_dict["hashed_password"] = get_password_hash(user_dict.pop("password"))
    user_dict["citizen_id"] = f"CITZ_{str(uuid.uuid4().int)[:5]}"

    new_user = await citizen_collection.insert_one(user_dict)
    created_user = await citizen_collection.find_one({"_id": new_user.inserted_id})
    return Citizen(**created_user)


@router.post("/login", response_model=Token)
async def login(login_data: CitizenLogin):
    user = await citizen_collection.find_one({"username": login_data.username})
    if not user or not verify_password(login_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        data={"sub": user["username"], "citizen_id": user["citizen_id"], "user_type": "citizen"}
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/query", response_model=CitizenQuery)
async def raise_query(
    query_data: CitizenQueryCreate,
    current_user: dict = Depends(get_current_citizen),
):
    query_dict = query_data.model_dump()
    query_dict["query_id"] = str(uuid.uuid4())
    query_dict["citizen_id"] = current_user["citizen_id"]
    query_dict["status"] = "Pending"
    query_dict["created_at"] = datetime.now().strftime("%Y-%m-%d")

    new_query = await citizen_query_collection.insert_one(query_dict)
    created_query = await citizen_query_collection.find_one({"_id": new_query.inserted_id})

    # Send email notification if citizen has a contact email
    contact = current_user.get("contact", "") or ""
    if contact and "@" in contact:
        await notify_complaint_received(
            citizen_contact=contact,
            description=query_dict["description"],
            query_id=query_dict["query_id"],
        )

    return CitizenQuery(**created_query)


@router.get("/queries", response_model=list[CitizenQuery])
async def get_my_queries(current_user: dict = Depends(get_current_citizen)):
    """Return all complaints submitted by the logged-in citizen."""
    citizen_id = current_user["citizen_id"]
    queries = []
    async for q in citizen_query_collection.find({"citizen_id": citizen_id}):
        q["_id"] = str(q["_id"])
        queries.append(CitizenQuery(**q))
    return queries


@router.get("/queries/all")
async def get_all_queries(limit: int = 100, skip: int = 0):
    """Return citizen complaints — for BMC dashboard. Paginated."""
    queries = []
    async for q in citizen_query_collection.find({}).sort("created_at", -1).skip(skip).limit(limit):
        q["_id"] = str(q["_id"])
        q.setdefault("status", "Pending")
        q.setdefault("created_at", "")
        queries.append(q)
    return queries


@router.post("/complaints/resolve/{query_id}")
async def resolve_complaint(query_id: str, request: ComplaintResolveRequest):
    """
    BMC action: Approve or Reject a citizen complaint.
    On Approve → optionally create a penalty for the contractor.
    """
    query = await citizen_query_collection.find_one({"query_id": query_id})
    if not query:
        raise HTTPException(status_code=404, detail="Complaint not found")

    action = request.action.lower()
    if action not in ("approve", "reject"):
        raise HTTPException(status_code=400, detail="Action must be 'approve' or 'reject'")

    new_status = "Resolved" if action == "approve" else "Rejected"
    await citizen_query_collection.update_one(
        {"query_id": query_id},
        {"$set": {"status": new_status, "resolved_at": datetime.now().isoformat()}}
    )

    penalty_id = None

    # On approve: create penalty if site_id and amount provided
    if action == "approve" and query.get("site_id") and request.penalty_amount:
        site = await site_collection.find_one({"site_id": query["site_id"]})
        if site:
            contractor_id = site.get("contractor_id", "")
            penalty_id = f"PEN_{int(datetime.now().timestamp())}"
            new_penalty = {
                "penalty_id": penalty_id,
                "site_id": query["site_id"],
                "contractor_id": contractor_id,
                "penalty_cost_rupees": request.penalty_amount,
                "penalty_status": "Active",
                "date_issued": datetime.now().strftime("%Y-%m-%d"),
                "reason": request.reason or f"Complaint approved: {query.get('description', '')}",
                "complaint_id": query_id,
            }
            await penalty_collection.insert_one(new_penalty)

            # Notify contractor
            contractor = await contractor_collection.find_one({"contractor_id": contractor_id})
            if contractor and contractor.get("email"):
                await notify_penalty_issued(
                    contractor_email=contractor["email"],
                    contractor_name=contractor.get("name", "Contractor"),
                    site_id=query["site_id"],
                    amount=request.penalty_amount,
                    reason=new_penalty["reason"],
                    penalty_id=penalty_id,
                    contractor_id=contractor_id,
                )

    return {
        "message": f"Complaint {new_status.lower()} successfully",
        "query_id": query_id,
        "status": new_status,
        "penalty_id": penalty_id,
    }
