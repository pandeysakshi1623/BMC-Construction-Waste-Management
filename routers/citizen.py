from fastapi import APIRouter, HTTPException, status, Depends
from database import citizen_collection, citizen_query_collection
from models.citizen import CitizenCreate, CitizenLogin, Citizen, CitizenQueryCreate, CitizenQuery
from models.token import Token
from utils.security import verify_password, get_password_hash, create_access_token
from utils.deps import get_current_citizen
from utils.notify import notify_complaint_received
import uuid
from datetime import datetime

router = APIRouter(prefix="/citizen", tags=["Citizen"])


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
async def get_all_queries():
    """Return all citizen complaints — for BMC dashboard."""
    queries = []
    async for q in citizen_query_collection.find({}):
        q["_id"] = str(q["_id"])
        q.setdefault("status", "Pending")
        q.setdefault("created_at", "")
        queries.append(q)
    return queries
