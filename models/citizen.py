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
    site_id: str
    citizen_query: str

class CitizenQuery(BaseModel):
    query_id: str
    citizen_id: str
    site_id: str
    contractor_id: str
    citizen_query: str
