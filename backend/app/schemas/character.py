from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from typing import List

class CharacterBase(BaseModel):
    name: str
    description: str
    system_prompt: str
    image_url: Optional[str] = None
    sample_contents: Optional[List[str]] = None
    sample_video_urls: Optional[List[str]] = None
    sample_audio_url: Optional[str] = None

class CharacterCreate(CharacterBase):
    pass

class CharacterUpdate(CharacterBase):
    name: Optional[str] = None
    description: Optional[str] = None
    system_prompt: Optional[str] = None
    image_url: Optional[str] = None

class CharacterResponse(CharacterBase):
    id: str
    creator_id: Optional[str] = None
    creator_name: str
    interactions: int
    created_at: datetime

    class Config:
        orm_mode = True
