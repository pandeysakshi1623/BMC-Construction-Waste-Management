from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from database import site_collection, contractor_collection, proof_history_collection
from models.site import SiteCreate, Site
from utils.deps import get_current_user
from utils.qr_generator import generate_qr_file
from utils.notify import notify_site_registered
from datetime import datetime, timezone
import uuid
import os

router = APIRouter(prefix="/sites", tags=["Sites"])

os.makedirs("uploads", exist_ok=True)


@router.post("/register", response_model=Site)
async def register_site(
    site_data: SiteCreate,
    current_user: dict = Depends(get_current_user),
):
    site_dict = site_data.model_dump()

    unique_site_id = f"SITE_{str(uuid.uuid4())[:8].upper()}"
    site_dict["site_id"] = unique_site_id
    site_dict["id"] = unique_site_id
    site_dict["contractor_id"] = current_user["contractor_id"]
    site_dict["status"] = "Active"
    site_dict["pickup_status"] = "Pending"

    qr_data_string = (
        f"SITE_ID:{unique_site_id}"
        f"|CONTRACTOR:{current_user['contractor_id']}"
        f"|NAME:{site_dict['site_name']}"
    )
    filename = f"{unique_site_id}_qr.png"
    qr_url = generate_qr_file(qr_data_string, filename)
    site_dict["qr_code_url"] = qr_url
    site_dict["qr_code"] = unique_site_id  # short ID used for scanning

    new_site = await site_collection.insert_one(site_dict)
    created_site = await site_collection.find_one({"_id": new_site.inserted_id})
    created_site["_id"] = str(created_site["_id"])

    # Notify contractor by email
    contractor = await contractor_collection.find_one(
        {"contractor_id": current_user["contractor_id"]}
    )
    if contractor and contractor.get("email"):
        await notify_site_registered(
            contractor_email=contractor["email"],
            contractor_name=contractor.get("name", "Contractor"),
            site_name=site_dict["site_name"],
            site_id=unique_site_id,
            contractor_id=current_user["contractor_id"],
        )

    return Site(**created_site)


@router.get("/by-qr/{site_id}")
async def get_site_by_qr(site_id: str):
    """
    Public endpoint — no auth required.
    Used by Citizens and BMC to fetch site details after scanning QR.
    """
    print(f"QR scan lookup for site_id: {site_id}")

    site = await site_collection.find_one({"site_id": site_id})
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")

    site["_id"] = str(site["_id"])
    site.setdefault("id", site.get("site_id", ""))
    site.setdefault("qr_code", site.get("qr_code_url", ""))
    site.setdefault("pickup_status", site.get("status", "Pending"))
    site.setdefault("waste_estimated", site.get("expected_waste", 0))
    site.setdefault("waste_actual", site.get("actual_waste", 0))
    site.setdefault("area", site.get("plot_size", 0))

    print(f"Site found: {site.get('site_name')}")
    return site


@router.get("/all")
async def get_all_sites(current_user: dict = Depends(get_current_user)):
    """Return only sites belonging to the authenticated contractor."""
    contractor_id = current_user.get("contractor_id")
    if not contractor_id:
        raise HTTPException(status_code=403, detail="Not a contractor account")

    cursor = site_collection.find({"contractor_id": contractor_id, "status": "Active"})
    sites = []
    async for site in cursor:
        site["id"] = site.get("site_id", str(site["_id"]))
        site["_id"] = str(site["_id"])
        # Normalize field names for Flutter SiteModel
        site.setdefault("qr_code", site.get("qr_code_url", ""))
        site.setdefault("pickup_status", site.get("status", "Pending"))
        site.setdefault("waste_estimated", site.get("expected_waste", 0))
        site.setdefault("waste_actual", site.get("actual_waste", 0))
        site.setdefault("area", site.get("plot_size", 0))
        sites.append(site)
    return sites


@router.post("/upload-proof")
async def upload_site_proof(
    site_id: str = Form(...),
    actual_waste: float = Form(...),
    image: UploadFile = File(...),
    driver_verified: bool = Form(False),  # optional — sent by Flutter
    current_user: dict = Depends(get_current_user),
):
    """Upload waste disposal proof image for a site."""
    print(f"Received site_id: {site_id}")
    print(f"Received actual_waste: {actual_waste}")
    print(f"Received file: {image.filename}")
    print(f"Driver verified: {driver_verified}")

    site = await site_collection.find_one({
        "site_id": site_id,
        "contractor_id": current_user["contractor_id"],
    })
    if not site:
        raise HTTPException(
            status_code=404,
            detail="Site not found or does not belong to your account",
        )

    contents = await image.read()
    image_filename = f"{uuid.uuid4()}_{image.filename}"
    file_path = f"uploads/{image_filename}"
    with open(file_path, "wb") as f:
        f.write(contents)

    await site_collection.update_one(
        {"site_id": site_id},
        {"$set": {"actual_waste": actual_waste, "proof_image_url": f"/static/{image_filename}"}},
    )

    history_entry = {
        "site_id": site_id,
        "image_url": f"/static/{image_filename}",
        "actual_waste": actual_waste,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "Completed",
        "driver_verified": driver_verified,
        "driver_name": "Demo Driver",
        "location": site.get("location", "Unknown Location"),
        "contractor_id": current_user["contractor_id"],
    }
    await proof_history_collection.insert_one(history_entry)

    print(f"Site proof uploaded: {file_path}")

    return {
        "message": "Upload successful",
        "image_url": f"/static/{image_filename}",
    }


@router.get("/proof-history/{site_id}")
async def get_proof_history(
    site_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Return all proof upload logs for a given site."""
    print(f"Fetching history for: {site_id}")

    cursor = proof_history_collection.find(
        {"site_id": site_id, "contractor_id": current_user["contractor_id"]},
    ).sort("timestamp", -1)  # Motor async uses .sort() chained, not as kwarg

    history = []
    async for entry in cursor:
        entry["_id"] = str(entry["_id"])
        history.append(entry)

    print(f"Proof history response ({len(history)} entries): {history}")
    return history
