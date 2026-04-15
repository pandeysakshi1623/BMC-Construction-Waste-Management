from pydantic import BaseModel, EmailStr
from typing import Optional

class Contractor(BaseModel):
    name: str
    contact: str
    address: str
    email: Optional[str] = None
    company_name: Optional[str] = None
    contractor_id: Optional[str] = None
    username: str
    hashed_password: str

class ContractorCreate(BaseModel):
    name: str
    contact: str
    address: str
    email: EmailStr          # required for contractors
    company_name: str
    username: str
    password: str

class DriverCreate(BaseModel):
    name: str
    contact: str
    username: str
    password: str

class ContractorLogin(BaseModel):
    username: str
    password: str
