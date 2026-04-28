from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from database import driver_location_collection, driver_rating_collection
from datetime import datetime

router = APIRouter(prefix="/driver", tags=["Driver"])


class LocationUpdate(BaseModel):
    driver_id: str
    latitude: float
    longitude: float
    timestamp: Optional[str] = None


class DriverRating(BaseModel):
    driver_id: str
    rating: int          # 1–5
    review: Optional[str] = None


@router.post("/location")
async def update_driver_location(body: LocationUpdate):
    """Store latest location for a driver (upsert)."""
    if not (1 <= body.rating if hasattr(body, 'rating') else True):
        pass  # no-op guard
    doc = {
        "driver_id": body.driver_id,
        "latitude": body.latitude,
        "longitude": body.longitude,
        "timestamp": body.timestamp or datetime.utcnow().isoformat(),
    }
    await driver_location_collection.update_one(
        {"driver_id": body.driver_id},
        {"$set": doc},
        upsert=True,
    )
    return {"message": "Location updated"}


@router.get("/location/{driver_id}")
async def get_driver_location(driver_id: str):
    """Return latest location for a driver."""
    doc = await driver_location_collection.find_one({"driver_id": driver_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Location not available")
    return {
        "driver_id": driver_id,
        "latitude": doc["latitude"],
        "longitude": doc["longitude"],
        "timestamp": doc.get("timestamp"),
    }


@router.post("/rating")
async def rate_driver(body: DriverRating):
    """Submit a rating (1–5) for a driver."""
    if not (1 <= body.rating <= 5):
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
    doc = {
        "driver_id": body.driver_id,
        "rating": body.rating,
        "review": body.review or "",
        "created_at": datetime.utcnow().isoformat(),
    }
    await driver_rating_collection.insert_one(doc)
    return {"message": "Rating submitted", "rating": body.rating}
