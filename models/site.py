from pydantic import BaseModel
from typing import Optional

class Site(BaseModel):
    site_id: str
    site_name: str
    location: str
    project_type: str
    plot_size: int
    contractor_id: str
    status: str = "Active"
    qr_code_url: Optional[str] = None

class SiteCreate(BaseModel):
    site_name: str
    location: str
    project_type: str
    plot_size: int
