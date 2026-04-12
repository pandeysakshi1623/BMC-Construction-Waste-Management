from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from typing import Optional
from database import pickup_collection, site_collection
from models.pickup import Pickup
from utils.deps import get_current_user
import uuid
import os
import random
from PIL import Image, ExifTags

router = APIRouter(prefix="/pickups", tags=["Pickups"])

# Ensure uploads directory exists
os.makedirs("uploads", exist_ok=True)

@router.post("/request", response_model=Pickup)
async def request_pickup(
    site_id: str = Form(...),
    waste_description: str = Form(...),
    est_weight_tons: float = Form(...),
    slot_time: str = Form(...), # format e.g. "10:00"
    date: str = Form(...), # format e.g. "13/04/26"
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    # Verify site belongs to contractor
    site = await site_collection.find_one({"site_id": site_id, "contractor_id": current_user["contractor_id"]})
    if not site:
        raise HTTPException(status_code=404, detail="Site not found or does not belong to your contractor account")
        
    # Read Image into PIL to verify EXIF Geotags
    image_bytes = await image.read()
    import io
    try:
        img = Image.open(io.BytesIO(image_bytes))
        exif = img._getexif()
        if not exif:
            raise ValueError("No EXIF data found")
            
        # Check for GPS Info (Tag 34853)
        gps_info_found = False
        for tag_id, val in exif.items():
            tag = ExifTags.TAGS.get(tag_id, tag_id)
            if tag == 'GPSInfo':
                gps_info_found = True
                break
                
        if not gps_info_found:
            raise ValueError("No GPSInfo tag found")
            
    except Exception as e:
        raise HTTPException(
            status_code=400, 
            detail="Image must be taken with location/geotagging enabled. Please capture picture directly using the app camera with location services turned on."
        )
        
    # Reset file pointer to save it
    image.file.seek(0)

    # Save Image to disk
    image_filename = f"{uuid.uuid4()}_{image.filename}"
    file_location = f"uploads/{image_filename}"
    with open(file_location, "wb+") as file_object:
        file_object.write(image.file.read())
        
    # Generate Request ID
    pickup_id = f"PKUP_REQ_{str(uuid.uuid4())[:8].upper()}"
    
    # Check availability against MongoDB seeding (Mock business rules)
    existing_count = await pickup_collection.count_documents({"slot_time": slot_time, "date": date})
    
    # Assume fleet handles 15 pickups per slot locally
    if existing_count < 15:
        availability = "Yes"
        status_text = "Scheduled Successfully"
        vehicle_num = f"MH 01 AB {random.randint(1000, 9999)}"
        # Mock Live GPS Tracking (generates near Mumbai coordinates)
        gps_url = f"https://maps.google.com/?q={random.uniform(18.9, 19.2):.4f},{random.uniform(72.8, 73.0):.4f}"
    else:
        availability = "No"
        status_text = "Rescheduled: Slot Capacity Reached"
        vehicle_num = "N/A"
        gps_url = None
        
    pickup_dict = {
        "pickup_id": pickup_id,
        "site_id": site_id,
        "contractor_id": current_user["contractor_id"],
        "waste_description": waste_description,
        "est_weight_tons": est_weight_tons,
        "slot_time": slot_time,
        "date": date,
        "vehicle_availability": availability,
        "assignment_status": status_text,
        "vehicle_number": vehicle_num,
        "image_url": f"/static/{image_filename}",
        "gps_tracking_url": gps_url
    }
    
    await pickup_collection.insert_one(pickup_dict)
    
    return Pickup(**pickup_dict)


@router.post("/upload-proof")
async def upload_pickup_proof(
    pickup_id: str = Form(...),
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload disposal proof image for a completed pickup."""
    pickup = await pickup_collection.find_one({"pickup_id": pickup_id})
    if not pickup:
        raise HTTPException(status_code=404, detail="Pickup not found")

    contents = await image.read()
    image_filename = f"{uuid.uuid4()}_{image.filename}"
    file_path = f"uploads/{image_filename}"
    with open(file_path, "wb") as f:
        f.write(contents)

    await pickup_collection.update_one(
        {"pickup_id": pickup_id},
        {"$set": {"disposal_proof_url": f"/static/{image_filename}"}},
    )

    print(f"Pickup proof uploaded: {file_path}")

    return {
        "message": "Pickup proof uploaded",
        "image_url": f"/static/{image_filename}",
    }
