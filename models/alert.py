from pydantic import BaseModel
from typing import Optional

class AlertCreate(BaseModel):
    recipient_type: str  # "BMC" or "Contractor"
    recipient_id: str
    message: str
    is_read: bool = False

class AlertResponse(BaseModel):
    alert_id: str
    recipient_type: str
    recipient_id: Optional[str] = None
    message: str
    is_read: bool = False
    # 'created_at' stored in DB; expose as both 'created_at' and 'timestamp' for Flutter
    created_at: Optional[str] = None
    timestamp: Optional[str] = None
    site_id: Optional[str] = None
