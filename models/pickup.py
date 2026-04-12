from pydantic import BaseModel
from typing import Optional

class Pickup(BaseModel):
    pickup_id: str
    site_id: str
    contractor_id: Optional[str] = None
    waste_description: str
    est_weight_tons: float
    slot_time: str
    date: str
    vehicle_availability: str
    assignment_status: str
    vehicle_number: Optional[str] = None
    image_url: Optional[str] = None
    gps_tracking_url: Optional[str] = None
