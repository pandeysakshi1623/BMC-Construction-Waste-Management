from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from database import site_collection, contractor_collection
from models.site import SiteCreate, Site
from utils.deps import get_current_user
from utils.qr_generator import generate_qr_file
from utils.notify import notify_site_registered
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
    current_user: dict = Depends(get_current_user),
):
    """Upload waste disposal proof image for a site."""
    # Verify site belongs to this contractor
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

    # Update actual waste in DB
    await site_collection.update_one(
        {"site_id": site_id},
        {"$set": {"actual_waste": actual_waste, "proof_image_url": f"/static/{image_filename}"}},
    )

    print(f"Site proof uploaded: {file_path}")

    return {
        "message": "Site proof uploaded",
        "image_url": f"/static/{image_filename}",
    }
