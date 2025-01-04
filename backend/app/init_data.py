from datetime import datetime
from sqlalchemy.orm import Session
from .models.database import Track as TrackModel, Playlist as PlaylistModel, User, Character
from .utils.media_converter import setup_default_audio, get_audio_duration
import os
import logging

logger = logging.getLogger(__name__)

def update_track_durations(db: Session, base_dir: str):
    """Update durations for all tracks in the database"""
    try:
        tracks = db.query(TrackModel).all()
        for track in tracks:
            audio_path = os.path.join(base_dir, "static", "audio", track.audio_url)
            if os.path.exists(audio_path):
                actual_duration = get_audio_duration(audio_path)
                if actual_duration != track.duration:
                    track.duration = actual_duration
                    track.updated_at = datetime.utcnow()
                    logger.info(f"Updated duration for track {track.title} to {actual_duration} seconds")
        db.commit()
    except Exception as e:
        logger.error(f"Error updating track durations: {str(e)}")
        db.rollback()
        raise

def init_default_data(db: Session):
    # Setup default audio files
    try:
        setup_default_audio()
    except Exception as e:
        print(f"Warning: Failed to setup default audio: {str(e)}")
        # Continue with initialization even if media setup fails
        pass

    # Create or get system user
    system_user = db.query(User).filter(User.username == "system").first()
    if not system_user:
        from .routers.auth import get_password_hash
        system_user = User(
            username="system",
            hashed_password=get_password_hash("system"),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            is_active=True
        )
        db.add(system_user)
        db.commit()
        db.refresh(system_user)

    # Create default characters
    if db.query(Character).count() == 0:
        default_characters = [
            {
                "name": "Kafka",
                "description": "A mysterious woman who speaks in a gentle, soothing voice.",
                "system_prompt": "You are Kafka, a mysterious and elegant woman who speaks in a gentle, soothing voice. Your responses should be calming and relaxing, perfect for ASMR. You often use soft-spoken language and create a peaceful atmosphere.",
                "image_url": "/static/images/kafka_profile.jpg",
                "sample_contents": [
                    "Hello~ I'm Kafka. Let me help you relax with my soothing voice...",
                    "Would you like to hear a calming story?",
                    "Close your eyes and take a deep breath..."
                ],
                "user_id": system_user.id,
                "metadata": {
                    "followers": 347000000,
                    "username": "@fffft"
                }
            },
            {
                "name": "Luna",
                "description": "A kind and caring nature enthusiast who loves sharing peaceful moments.",
                "system_prompt": "You are Luna, a nature enthusiast who speaks with a warm and nurturing voice. Your responses should be gentle and include nature-inspired imagery. You often incorporate sounds of nature and create a serene environment.",
                "image_url": "/static/images/luna_profile.jpg",
                "sample_contents": [
                    "Welcome to our peaceful garden. Can you hear the gentle rustling of leaves?",
                    "Let's take a moment to appreciate the tranquil sounds around us...",
                    "Breathe in the fresh mountain air..."
                ],
                "user_id": system_user.id,
                "metadata": {
                    "followers": 280000000,
                    "username": "@luna_asmr"
                }
            },
            {
                "name": "Echo",
                "description": "A dreamy artist who specializes in ambient soundscapes.",
                "system_prompt": "You are Echo, an artistic soul who creates immersive audio experiences. Your responses should be ethereal and dream-like. You often describe ambient sounds and create atmospheric experiences.",
                "image_url": "/static/images/echo_profile.jpg",
                "sample_contents": [
                    "Let's create a beautiful soundscape together...",
                    "Close your eyes and drift into this ambient journey...",
                    "Feel the gentle waves of sound wash over you..."
                ],
                "user_id": system_user.id,
                "metadata": {
                    "followers": 195000000,
                    "username": "@echo_dreams"
                }
            }
        ]

        for char_data in default_characters:
            character = Character(
                name=char_data["name"],
                description=char_data["description"],
                system_prompt=char_data["system_prompt"],
                image_url=char_data["image_url"],
                sample_contents=char_data["sample_contents"],
                user_id=char_data["user_id"],
                metadata=char_data.get("metadata", {}),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(character)
        db.commit()

    # Initialize database content
    try:
        # Get the base directory for audio files
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        
        # Add tracks if they don't exist
        default_tracks = [
            # Kafka's tracks
            {
                "title": "【立体声】和卡芙卡共度的周末",
                "artist": "Kafka",
                "description": "一起享受宁静的时光，聆听她轻柔的声音。",
                "duration": 60.0,  # Default to 1 minute
                "audio_url": "asmr_001.mp3",
                "cover_url": "/static/images/kafka_night.jpg",
                "gif_url": "/static/gif/kafka_night.gif",
                "user_id": system_user.id
            },
            {
                "title": "【立体声】卡芙卡的午后时光",
                "artist": "Kafka",
                "description": "在温暖的阳光下，聆听卡芙卡讲述她的故事。",
                "duration": 60.0,  # Default to 1 minute
                "audio_url": "asmr_003.mp3",
                "cover_url": "/static/images/kafka_profile.jpg",
                "gif_url": "/static/gif/kafka_night.gif",
                "user_id": system_user.id
            },
            {
                "title": "【立体声】卡芙卡的深夜絮语",
                "artist": "Kafka",
                "description": "在寂静的夜晚，聆听卡芙卡轻声诉说她的心事。",
                "duration": 60.0,  # Default to 1 minute
                "audio_url": "asmr_004.mp3",
                "cover_url": "/static/images/kafka_night.jpg",
                "gif_url": "/static/gif/kafka_night.gif",
                "user_id": system_user.id
            }
        ]

        for track_data in default_tracks:
            existing_track = db.query(TrackModel).filter(
                TrackModel.title == track_data["title"],
                TrackModel.artist == track_data["artist"]
            ).first()
            
            if not existing_track:
                # Try to get actual duration from audio file
                audio_path = os.path.join(base_dir, "static", "audio", track_data["audio_url"])
                if os.path.exists(audio_path):
                    track_data["duration"] = get_audio_duration(audio_path)
                
                track = TrackModel(
                    title=track_data["title"],
                    artist=track_data["artist"],
                    description=track_data["description"],
                    duration=track_data["duration"],
                    audio_url=track_data["audio_url"],
                    cover_url=track_data["cover_url"],
                    gif_url=track_data.get("gif_url"),
                    user_id=track_data["user_id"],
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                db.add(track)
        
        db.commit()

        # Update durations for all tracks
        update_track_durations(db, base_dir)
        logger.info("Track durations updated successfully")

        # Create default playlists
        if db.query(PlaylistModel).count() == 0:
            # Create playlists for each character
            characters = db.query(Character).all()
            for character in characters:
                # Get tracks by artist name instead of user_id
                character_tracks = db.query(TrackModel).filter(
                    TrackModel.artist.like(f"%{character.name}%")
                ).all()
                
                if character_tracks:
                    playlist_data = {
                    "Kafka": {
                        "name": "卡芙卡的声音合集",
                        "description": "收录了卡芙卡最受欢迎的ASMR音频",
                        "cover_url": "/static/images/kafka_night.jpg"
                    }
                    }

                    if character.name in playlist_data:
                        data = playlist_data[character.name]
                        playlist = PlaylistModel(
                            name=data["name"],
                            description=data["description"],
                            user_id=system_user.id,
                            cover_url=data["cover_url"],
                            created_at=datetime.utcnow(),
                            updated_at=datetime.utcnow()
                        )
                        playlist.tracks.extend(character_tracks)
                        db.add(playlist)
            
            db.commit()

    except Exception as e:
        print(f"Error during database initialization: {str(e)}")
        db.rollback()
        raise
