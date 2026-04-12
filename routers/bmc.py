from fastapi import APIRouter, HTTPException, Depends, Request
from database import official_collection, penalty_collection, bmc_master_collection, citizen_collection, site_collection, pickup_collection
from models.bmc import BMCOfficialLogin, PenaltyRequest, TruckApprovalRequest
from bson import ObjectId
from utils.security import create_access_token, verify_password, get_password_hash
from datetime import datetime, timedelta

router = APIRouter(prefix="/bmc", tags=["BMC Officials"])

# Create a default admin official if auth needed, but will just check static user for simplicity today if it's not seeded properly
# But we seeded it in our script

@router.post("/login")
async def login(official: BMCOfficialLogin):
    user = await official_collection.find_one({"username": official.username})
    if not user or not verify_password(official.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    access_token = create_access_token(data={"sub": user["username"], "role": "bmc_official"})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/qr-scan/{site_id}")
async def fetch_site_details(site_id: str):
    """
    Simulated QR Scan: fetches the site details, active penalties, & related contractor.
    """
    site = await site_collection.find_one({"site_id": site_id})
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
    
    # We can also fetch the master db details for this site
    master_info = await bmc_master_collection.find_one({"site_id": site_id})
    penalties = await penalty_collection.find({"site_id": site_id, "penalty_status": "Active"}).to_list(100)
    
    # Fix ObjectId serialization
    if site and "_id" in site:
        site["_id"] = str(site["_id"])
    if master_info and "_id" in master_info:
        master_info["_id"] = str(master_info["_id"])
    for p in penalties:
        if "_id" in p:
            p["_id"] = str(p["_id"])
            
    return {
        "site": site,
        "master_record": master_info,
        "active_penalties": penalties
    }

@router.post("/penalties/{site_id}")
async def issue_penalty(site_id: str, request: PenaltyRequest):
    site = await site_collection.find_one({"site_id": site_id})
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
        
    contractor_id = site.get("contractor_id")
    
    new_penalty = {
        "penalty_id": f"PEN_{int(datetime.now().timestamp())}",
        "site_id": site_id,
        "contractor_id": str(contractor_id),
        "penalty_cost_rupees": request.penalty_cost_rupees,
        "penalty_status": "Active",
        "date_issued": datetime.now().strftime("%Y-%m-%d"),
        "reason": request.reason
    }
    
    await penalty_collection.insert_one(new_penalty)
    
    # Update master DB record logic (increment active_penalties)
    await bmc_master_collection.update_one(
        {"site_id": site_id},
        {"$inc": {"active_penalties": 1}}
    )
    
    return {"message": "Penalty issued successfully", "penalty_id": new_penalty["penalty_id"]}

@router.get("/dashboard")
async def bmc_dashboard():
    """
    Aggregated Analytical Dashboard for BMC Officials.
    """
    total_active_penalties = await penalty_collection.count_documents({"penalty_status": "Active"})
    total_dead_penalties = await penalty_collection.count_documents({"penalty_status": "Dead"})
    total_sites = await site_collection.count_documents({})
    
    # Get pending truck approvals
    pending_trucks = await pickup_collection.find({"assignment_status": "Pending Approval"}).to_list(100)
    for t in pending_trucks:
        t["_id"] = str(t["_id"])
        
    return {
        "dashboard_stats": {
            "total_sites": total_sites,
            "active_penalties": total_active_penalties,
            "resolved_penalties": total_dead_penalties
        },
        "pending_truck_approvals": pending_trucks
    }

@router.post("/trucks/{pickup_id}/approve")
async def approve_truck(pickup_id: str, request: TruckApprovalRequest):
    try:
        obj_id = ObjectId(pickup_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid pickup ID format")
        
    pickup = await pickup_collection.find_one({"_id": obj_id})
    if not pickup:
        raise HTTPException(status_code=404, detail="Pickup request not found")
        
    status = "Approved" if request.status.lower() == "approved" else "Rejected"
    
    await pickup_collection.update_one(
        {"_id": obj_id},
        {"$set": {"assignment_status": status}}
    )
    
    return {"message": f"Truck request {status.lower()} successfully."}

@router.get("/penalties/by-site")
async def get_penalties_by_site():
    """
    Get penalties grouped by site.
    """
    pipeline = [
        {"$match": {"penalty_status": "Active"}},
        {"$group": {
            "_id": "$site_id",
            "total_penalty_rupees": {"$sum": "$penalty_cost_rupees"},
            "penalties": {"$push": {
                "penalty_id": "$penalty_id",
                "penalty_cost_rupees": "$penalty_cost_rupees",
                "date_issued": "$date_issued",
                "reason": "$reason"
            }}
        }}
    ]
    cursor = penalty_collection.aggregate(pipeline)
    results = []
    async for group in cursor:
        results.append({
            "site_id": group["_id"],
            "total_penalty_rupees": group["total_penalty_rupees"],
            "penalties": group["penalties"]
        })
    return results

