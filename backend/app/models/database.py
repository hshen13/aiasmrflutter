from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, JSON, Boolean, Float, Table
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
from ..schemas.audio import Track as TrackSchema
import uuid

Base = declarative_base()

def generate_uuid():
    return str(uuid.uuid4())

# Association tables
playlist_tracks = Table(
    'playlist_tracks',
    Base.metadata,
    Column('playlist_id', String(36), ForeignKey('playlists.id', ondelete="CASCADE")),
    Column('track_id', String(36), ForeignKey('tracks.id', ondelete="CASCADE")),
)

user_favorites = Table(
    'user_favorites',
    Base.metadata,
    Column('user_id', String(36), ForeignKey('users.id', ondelete="CASCADE")),
    Column('track_id', String(36), ForeignKey('tracks.id', ondelete="CASCADE")),
)

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    avatar_url = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    characters = relationship("Character", back_populates="user", cascade="all, delete-orphan")
    chats = relationship("Chat", back_populates="user", cascade="all, delete-orphan")
    playlists = relationship("Playlist", back_populates="user", cascade="all, delete-orphan")
    recently_played = relationship("RecentlyPlayed", back_populates="user", cascade="all, delete-orphan")
    tracks = relationship("Track", back_populates="user", cascade="all, delete-orphan")
    favorite_tracks = relationship("Track", secondary=user_favorites, back_populates="favorited_by")

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "avatar_url": self.avatar_url,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "is_active": self.is_active
        }

class Track(Base):
    __tablename__ = "tracks"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    title = Column(String(100), nullable=False)
    artist = Column(String(100), nullable=False)
    duration = Column(Float, nullable=False)
    audio_url = Column(String(255), nullable=False)
    cover_url = Column(String(255))
    gif_url = Column(String(255), default='/static/gif/kafka_night.gif')
    description = Column(Text)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="tracks")
    playlists = relationship("Playlist", secondary=playlist_tracks, back_populates="tracks")
    recently_played = relationship("RecentlyPlayed", back_populates="track")
    favorited_by = relationship("User", secondary=user_favorites, back_populates="favorite_tracks")

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title or "",
            "description": self.description or "",
            "artist": self.artist,
            "duration": self.duration,
            "audio_url": self.audio_url,
            "cover_url": self.cover_url,
            "gif_url": self.gif_url,
            "user_id": self.user_id,
            "username": self.user.username if self.user else None,
            "user_avatar": self.user.avatar_url if hasattr(self.user, 'avatar_url') else None,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }

class Playlist(Base):
    __tablename__ = "playlists"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    cover_url = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="playlists")
    tracks = relationship("Track", secondary=playlist_tracks, back_populates="playlists")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "description": self.description,
            "cover_url": self.cover_url,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "track_count": len(self.tracks),
            "tracks": [TrackSchema.from_orm(track) for track in self.tracks] if self.tracks else []
        }

class RecentlyPlayed(Base):
    __tablename__ = "recently_played"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    track_id = Column(String(36), ForeignKey("tracks.id", ondelete="CASCADE"), nullable=False)
    played_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="recently_played")
    track = relationship("Track", back_populates="recently_played")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "track_id": self.track_id,
            "played_at": self.played_at.isoformat(),
            "track": TrackSchema.from_orm(self.track)
        }

class Character(Base):
    __tablename__ = "characters"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(50), nullable=False)
    description = Column(Text)
    system_prompt = Column(Text, nullable=False)
    image_url = Column(String(255))
    interactions = Column(Integer, default=0, nullable=False)
    sample_contents = Column(JSON, nullable=False, default=lambda: ["这是一个新创建的角色。", "你可以开始和它聊天了。"])
    sample_video_urls = Column(JSON, nullable=False, default=list)
    sample_audio_url = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="characters")
    chats = relationship("Chat", back_populates="character", cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "description": self.description or "",
            "system_prompt": self.system_prompt,
            "image_url": self.image_url or "",
            "interactions": self.interactions,
            "creator_id": self.user_id,
            "creator_name": self.user.username if self.user else "system",
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "sample_contents": self.sample_contents or [],
            "sample_video_urls": self.sample_video_urls or [],
            "sample_audio_url": self.sample_audio_url or ""
        }

class Chat(Base):
    __tablename__ = "chats"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    character_id = Column(String(36), ForeignKey("characters.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(100))  # Make title nullable
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="chats")
    character = relationship("Character", back_populates="chats")
    messages = relationship("Message", back_populates="chat", cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "character_id": self.character_id,
            "title": self.title or "",
            "description": self.description or "",
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "character": self.character.to_dict() if self.character else None,
            "last_message": (
                sorted(self.messages, key=lambda x: x.created_at, reverse=True)[0].to_dict()
                if self.messages else None
            )
        }

class Message(Base):
    __tablename__ = "messages"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    chat_id = Column(String(36), ForeignKey("chats.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String(20), nullable=False)  # text, image, audio, video
    is_from_user = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Optional fields for different message types
    duration = Column(Float)  # For audio/video messages
    thumbnail_url = Column(String(255))  # For image/video messages
    media_url = Column(String(255))  # For image/audio/video messages

    # Relationships
    chat = relationship("Chat", back_populates="messages")

    def to_dict(self):
        return {
            "id": self.id,
            "chat_id": self.chat_id,
            "content": self.content,
            "type": self.type,
            "is_user": self.is_from_user,
            "created_at": self.created_at.isoformat(),
            "duration": self.duration or 0.0,
            "thumbnail_url": self.thumbnail_url or "",
            "media_url": self.media_url or ""
        }
