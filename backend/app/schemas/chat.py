from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict, Any
from .character import CharacterResponse

class ChatBase(BaseModel):
    character_id: str
    title: Optional[str] = None
    description: Optional[str] = None

class ChatCreate(ChatBase):
    pass

class ChatUpdate(ChatBase):
    character_id: Optional[str] = None

class MessageBase(BaseModel):
    content: str
    type: str = "text"

class MessageCreate(MessageBase):
    pass

class MessageResponse(MessageBase):
    id: str
    chat_id: str
    is_user: bool
    created_at: datetime
    duration: Optional[float] = None
    thumbnail_url: Optional[str] = None
    media_url: Optional[str] = None

    class Config:
        orm_mode = True

class LastMessage(MessageResponse):
    pass

class ChatResponse(BaseModel):
    id: str
    user_id: str
    character_id: str
    title: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    character: Optional[CharacterResponse] = None
    last_message: Optional[LastMessage] = None

    class Config:
        orm_mode = True

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    limit: int
    pages: int

class ChatListResponse(PaginatedResponse):
    items: List[ChatResponse]

class MessageListResponse(PaginatedResponse):
    items: List[MessageResponse]

class MessagesResponse(BaseModel):
    messages: List[MessageResponse]
