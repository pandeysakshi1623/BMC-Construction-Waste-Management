from pydantic import BaseModel
from typing import Optional

class Token(BaseModel):
    access_token: str
    token_type: str
    role: Optional[str] = None  # returned by /auth/login so frontend knows contractor vs driver

class TokenData(BaseModel):
    username: Optional[str] = None
