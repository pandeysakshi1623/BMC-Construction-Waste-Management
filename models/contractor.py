from pydantic import BaseModel, EmailStr
from typing import Optional

class Contractor(BaseModel):
    name: str
    contact: str
    address: str
    email: EmailStr
    company_name: str
    contractor_id: Optional[str] = None
    username: str
    hashed_password: str

class ContractorCreate(BaseModel):
    name: str
    contact: str
    address: str
    email: EmailStr
    company_name: str
    username: str
    password: str

class ContractorLogin(BaseModel):
    username: str
    password: str