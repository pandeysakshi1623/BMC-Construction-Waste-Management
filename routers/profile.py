from fastapi import APIRouter, HTTPException, Depends
from database import contractor_collection, citizen_collection, official_collection
from utils.deps import get_current_user, get_current_citizen
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/profile", tags=["Profile"])


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    contact: Optional[str] = None
    email: Optional[str] = None
    company_name: Optional[str] = None
    address: Optional[str] = None


def _clean(doc: dict) -> dict:
    doc.pop("_id", None)
    doc.pop("hashed_password", None)
    return doc


# ── Contractor / Driver ───────────────────────────────────────────────────────

@router.get("/contractor")
async def get_contractor_profile(current_user: dict = Depends(get_current_user)):
    return _clean(dict(current_user))


@router.put("/contractor")
async def update_contractor_profile(
    data: ProfileUpdate,
    current_user: dict = Depends(get_current_user),
):
    update = {k: v for k, v in data.model_dump().items() if v is not None}
    if not update:
        raise HTTPException(status_code=400, detail="No fields to update")

    await contractor_collection.update_one(
        {"contractor_id": current_user["contractor_id"]},
        {"$set": update},
    )
    updated = await contractor_collection.find_one(
        {"contractor_id": current_user["contractor_id"]}
    )
    return _clean(dict(updated))


@router.delete("/contractor")
async def delete_contractor_profile(current_user: dict = Depends(get_current_user)):
    await contractor_collection.delete_one(
        {"contractor_id": current_user["contractor_id"]}
    )
    return {"message": "Account deleted"}


# ── Citizen ───────────────────────────────────────────────────────────────────

@router.get("/citizen")
async def get_citizen_profile(current_user: dict = Depends(get_current_citizen)):
    return _clean(dict(current_user))


@router.put("/citizen")
async def update_citizen_profile(
    data: ProfileUpdate,
    current_user: dict = Depends(get_current_citizen),
):
    update = {k: v for k, v in data.model_dump().items() if v is not None}
    if not update:
        raise HTTPException(status_code=400, detail="No fields to update")

    await citizen_collection.update_one(
        {"citizen_id": current_user["citizen_id"]},
        {"$set": update},
    )
    updated = await citizen_collection.find_one(
        {"citizen_id": current_user["citizen_id"]}
    )
    return _clean(dict(updated))


@router.delete("/citizen")
async def delete_citizen_profile(current_user: dict = Depends(get_current_citizen)):
    await citizen_collection.delete_one(
        {"citizen_id": current_user["citizen_id"]}
    )
    return {"message": "Account deleted"}
