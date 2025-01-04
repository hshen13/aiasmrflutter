from pydantic import BaseModel
from typing import Optional

class User(BaseModel):
    id: Optional[int] = None
    username: str
    hashed_password: str

class UserCreate(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
