from pydantic import BaseModel
from typing import Optional

class CitizenCreate(BaseModel):
    username: str
    password: str
    name: Optional[str] = None
    contact: Optional[str] = None

class CitizenLogin(BaseModel):
    username: str
    password: str

class Citizen(BaseModel):
    citizen_id: str
    username: str
    name: Optional[str] = None
    contact: Optional[str] = None

class CitizenQueryCreate(BaseModel):
    description: str
    location: str

class CitizenQuery(BaseModel):
    query_id: str
    citizen_id: str
    description: str
    location: str
    status: Optional[str] = "Pending"
    created_at: Optional[str] = None
