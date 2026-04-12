from fastapi import APIRouter, Depends, HTTPException, status
from database import site_collection
from models.site import SiteCreate, Site
from utils.deps import get_current_user
from utils.qr_generator import generate_qr_file
import uuid

router = APIRouter(prefix="/sites", tags=["Sites"])

@router.post("/register", response_model=Site)
async def register_site(site_data: SiteCreate, current_user: dict = Depends(get_current_user)):
    site_dict = site_data.dict()
    
    # Generate unique Site ID
    unique_site_id = f"SITE_{str(uuid.uuid4())[:8].upper()}"
    site_dict["site_id"] = unique_site_id
    site_dict["contractor_id"] = current_user["contractor_id"]
    site_dict["status"] = "Active"
    
    # Generate QR Code representing the site ID as a physical file
    qr_data_string = f"SITE_ID:{unique_site_id}|CONTRACTOR:{current_user['contractor_id']}|NAME:{site_dict['site_name']}"
    filename = f"{unique_site_id}_qr.png"
    site_dict["qr_code_url"] = generate_qr_file(qr_data_string, filename)
    
    new_site = await site_collection.insert_one(site_dict)
    created_site = await site_collection.find_one({"_id": new_site.inserted_id})
    
    return Site(**created_site)

@router.get("/all")
async def get_all_sites():
    # Only return Active sites for dropdowns
    cursor = site_collection.find({"status": "Active"})
    sites = []
    async for site in cursor:
        site["_id"] = str(site["_id"])
        sites.append(site)
    return sites
