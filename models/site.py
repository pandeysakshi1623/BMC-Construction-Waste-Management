from pydantic import BaseModel
from typing import Optional

class Site(BaseModel):
    id: Optional[str] = None
    site_id: str
    site_name: str
    location: str
    project_type: str
    plot_size: int
    contractor_id: str
    status: str = "Active"
    pickup_status: str = "Pending"
    qr_code_url: Optional[str] = None
    qr_code: Optional[str] = None       # short ID for scanning
    waste_estimated: Optional[float] = 0
    waste_actual: Optional[float] = 0

class SiteCreate(BaseModel):
    site_name: str
    location: str
    project_type: str
    plot_size: int
