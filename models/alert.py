from pydantic import BaseModel
from typing import Optional, List

class AlertCreate(BaseModel):
    recipient_type: str  # "BMC" or "Contractor"
    recipient_id: str    # "BMC_MASTER" or contractor_id
    message: str
    is_read: bool = False

class AlertResponse(BaseModel):
    alert_id: str
    recipient_type: str
    recipient_id: str
    message: str
    is_read: bool
    created_at: str
