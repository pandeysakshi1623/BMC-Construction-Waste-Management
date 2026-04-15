from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional
from database import pickup_collection, site_collection, contractor_collection
from utils.deps import get_current_user
from utils.notify import notify_pickup_scheduled, notify_pickup_status_changed
import uuid, os

router = APIRouter(prefix="/pickups", tags=["Pickups"])
os.makedirs("uploads", exist_ok=True)


class PickupRequest(BaseModel):
    site_id: str
    scheduled_date: str


class StatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None


def _serialize(p: dict) -> dict:
    p["id"] = p.get("pickup_id", str(p.get("_id", "")))
    p["_id"] = str(p.get("_id", ""))
    p.setdefault("site_name", p.get("site_id", ""))
    p.setdefault("location", "")
    p.setdefault("waste_type", "Construction Waste")
    p.setdefault("qr_code", p.get("site_id", ""))
    p.setdefault("driver_id", None)
    p.setdefault("driver_name", None)
    p.setdefault("driver_phone", None)
    p.setdefault("driver_vehicle", None)
    p.setdefault("notes", None)
    return p


@router.post("/request")
async def request_pickup(
    body: PickupRequest,
    current_user: dict = Depends(get_current_user),
):
    site = await site_collection.find_one(
        {"site_id": body.site_id, "contractor_id": current_user["contractor_id"]}
    )
    if not site:
        raise HTTPException(status_code=404, detail="Site not found or does not belong to your account")

    pickup_id = f"PKUP_{str(uuid.uuid4())[:8].upper()}"
    pickup_dict = {
        "pickup_id": pickup_id,
        "site_id": body.site_id,
        "site_name": site.get("site_name", body.site_id),
        "location": site.get("location", ""),
        "contractor_id": current_user["contractor_id"],
        "scheduled_date": body.scheduled_date,
        "status": "Pending",
        "waste_type": "Construction Waste",
        "qr_code": site.get("site_id", body.site_id),
    }
    await pickup_collection.insert_one(pickup_dict)

    contractor = await contractor_collection.find_one({"contractor_id": current_user["contractor_id"]})
    if contractor:
        await notify_pickup_scheduled(
            contractor_email=contractor.get("email", ""),
            contractor_name=contractor.get("name", "Contractor"),
            site_name=site.get("site_name", body.site_id),
            pickup_id=pickup_id,
            scheduled_date=body.scheduled_date,
            contractor_id=current_user["contractor_id"],
            site_id=body.site_id,
        )

    return {"message": "Pickup scheduled successfully", "pickup_id": pickup_id}


@router.get("/driver")
async def get_driver_pickups(current_user: dict = Depends(get_current_user)):
    """Return all pickups assigned to or available for the logged-in driver."""
    pickups = []
    async for p in pickup_collection.find({}):
        pickups.append(_serialize(p))
    return pickups


@router.get("/contractor")
async def get_contractor_pickups(current_user: dict = Depends(get_current_user)):
    """Return all pickups for the logged-in contractor's sites."""
    pickups = []
    async for p in pickup_collection.find({"contractor_id": current_user["contractor_id"]}):
        pickups.append(_serialize(p))
    return pickups


@router.patch("/{pickup_id}/status")
async def update_pickup_status(
    pickup_id: str,
    body: StatusUpdate,
    current_user: dict = Depends(get_current_user),
):
    pickup = await pickup_collection.find_one({"pickup_id": pickup_id})
    if not pickup:
        raise HTTPException(status_code=404, detail="Pickup not found")

    update = {"status": body.status}
    if body.notes:
        update["notes"] = body.notes

    await pickup_collection.update_one({"pickup_id": pickup_id}, {"$set": update})

    # Notify contractor of status change
    contractor = await contractor_collection.find_one({"contractor_id": pickup.get("contractor_id")})
    if contractor:
        await notify_pickup_status_changed(
            contractor_email=contractor.get("email", ""),
            contractor_name=contractor.get("name", "Contractor"),
            site_name=pickup.get("site_name", pickup.get("site_id", "")),
            pickup_id=pickup_id,
            new_status=body.status,
            contractor_id=pickup.get("contractor_id", ""),
            site_id=pickup.get("site_id", ""),
        )

    return {"message": f"Status updated to {body.status}"}


@router.post("/upload-proof")
async def upload_pickup_proof(
    pickup_id: str = Form(...),
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    pickup = await pickup_collection.find_one({"pickup_id": pickup_id})
    if not pickup:
        raise HTTPException(status_code=404, detail="Pickup not found")

    contents = await image.read()
    fname = f"{uuid.uuid4()}_{image.filename}"
    with open(f"uploads/{fname}", "wb") as f:
        f.write(contents)

    await pickup_collection.update_one(
        {"pickup_id": pickup_id},
        {"$set": {"disposal_proof_url": f"/static/{fname}"}},
    )
    return {"message": "Proof uploaded", "image_url": f"/static/{fname}"}
