from pydantic import BaseModel, EmailStr, Field, validator
from datetime import datetime
from typing import Optional, List
import re

USERNAME_PATTERN = re.compile(r'^[a-zA-Z0-9_-]{3,20}$')
PASSWORD_MIN_LENGTH = 8

class Token(BaseModel):
    access_token: str
    token_type: str = Field(default="bearer")

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=20)

    @validator('username')
    def validate_username(cls, v):
        if not USERNAME_PATTERN.match(v):
            raise ValueError("用户名只能包含字母、数字、下划线和连字符，长度在3-20个字符之间")
        return v

class UserCreate(UserBase):
    password: str = Field(..., min_length=PASSWORD_MIN_LENGTH)

    @validator('password')
    def validate_password(cls, v):
        if len(v) < PASSWORD_MIN_LENGTH:
            raise ValueError(f"密码长度不能少于{PASSWORD_MIN_LENGTH}个字符")
        return v

class UserResponse(BaseModel):
    id: str
    username: str
    is_active: bool
    avatar_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

    @validator('created_at', 'updated_at', pre=True)
    def parse_datetime(cls, value):
        if isinstance(value, str):
            return datetime.fromisoformat(value.replace('Z', '+00:00'))
        return value

class LoginRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=20)
    password: str = Field(..., min_length=PASSWORD_MIN_LENGTH)

    @validator('username')
    def validate_username(cls, v):
        if not USERNAME_PATTERN.match(v):
            raise ValueError("用户名只能包含字母、数字、下划线和连字符，长度在3-20个字符之间")
        return v

    @validator('password')
    def validate_password(cls, v):
        if len(v) < PASSWORD_MIN_LENGTH:
            raise ValueError(f"密码长度不能少于{PASSWORD_MIN_LENGTH}个字符")
        return v

class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = Field(default="bearer")
    user: UserResponse

class TokenData(BaseModel):
    username: Optional[str] = None
    exp: Optional[datetime] = None
    type: Optional[str] = None

    @validator('exp', pre=True)
    def parse_expiration(cls, value):
        if isinstance(value, (int, float)):
            return datetime.fromtimestamp(value)
        return value

class RefreshRequest(BaseModel):
    refresh_token: str = Field(..., description="The refresh token to use for getting new access token")

class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = Field(default="bearer")

class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None
    params: Optional[dict] = None

    class Config:
        schema_extra = {
            "example": {
                "detail": "用户名或密码错误",
                "code": "invalid_credentials",
                "params": {"field": "password"}
            }
        }
