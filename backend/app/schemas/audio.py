from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class TrackBase(BaseModel):
    title: str
    description: Optional[str] = None
    artist: str
    duration: float
    audio_url: str
    cover_url: Optional[str] = None
    gif_url: Optional[str] = '/static/gif/kafka_night.gif'
    user_id: str

class UserInfo(BaseModel):
    id: str
    username: str
    avatar_url: Optional[str] = None

class TrackCreate(TrackBase):
    pass

class Track(TrackBase):
    id: str
    created_at: datetime
    updated_at: datetime
    username: Optional[str] = None
    user_avatar: Optional[str] = None

    @staticmethod
    def from_orm(db_obj):
        # Get the user info
        username = db_obj.user.username if db_obj.user else None
        user_avatar = db_obj.user.avatar_url if db_obj.user else None
        
        # Create a dict of the database object
        obj_dict = {
            "id": db_obj.id,
            "title": db_obj.title,
            "description": db_obj.description,
            "artist": db_obj.artist,
            "duration": db_obj.duration,
            "audio_url": db_obj.audio_url,
            "cover_url": db_obj.cover_url,
            "gif_url": db_obj.gif_url,
            "user_id": db_obj.user_id,
            "username": username,
            "user_avatar": user_avatar,
            "created_at": db_obj.created_at,
            "updated_at": db_obj.updated_at,
        }
        return Track(**obj_dict)

    class Config:
        orm_mode = True

class PlaylistBase(BaseModel):
    name: str
    description: Optional[str] = None
    cover_url: Optional[str] = None

class PlaylistCreate(PlaylistBase):
    pass

class PlaylistUpdate(PlaylistBase):
    pass

class Playlist(PlaylistBase):
    id: str
    user_id: str
    creator_name: str
    created_at: datetime
    updated_at: datetime
    track_count: int
    tracks: Optional[List[Track]] = None

    @staticmethod
    def from_orm(db_obj):
        # Get the creator name from the user relationship
        creator_name = db_obj.user.username if db_obj.user else "System"
        
        # Create a dict of the database object
        obj_dict = {
            "id": db_obj.id,
            "name": db_obj.name,
            "description": db_obj.description,
            "user_id": db_obj.user_id,
            "creator_name": creator_name,
            "cover_url": db_obj.cover_url,
            "tracks": db_obj.tracks,
            "track_count": len(db_obj.tracks),
            "created_at": db_obj.created_at,
            "updated_at": db_obj.updated_at,
        }
        return Playlist(**obj_dict)

    class Config:
        orm_mode = True

class PlaylistAddTrack(BaseModel):
    track_id: str

class PlaylistRemoveTrack(BaseModel):
    track_id: str

class RecentlyPlayedCreate(BaseModel):
    track_id: str

class RecentlyPlayed(BaseModel):
    id: str
    user_id: str
    track_id: str
    played_at: datetime
    track: Track

    class Config:
        orm_mode = True

class AudioResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

    class Config:
        orm_mode = True
