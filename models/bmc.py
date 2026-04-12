from pydantic import BaseModel, Field
from typing import Optional

class BMCOfficialLogin(BaseModel):
    username: str
    password: str

class PenaltyRequest(BaseModel):
    penalty_cost_rupees: int = Field(..., gt=0)
    reason: Optional[str] = "QR Scanned Issue"

class TruckApprovalRequest(BaseModel):
    status: str = Field(..., description="Approved or Rejected")
