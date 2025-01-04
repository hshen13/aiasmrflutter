from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError
from .models.database import Base, User, Track, Playlist
from .config import settings
import logging

logger = logging.getLogger(__name__)

# Create database engine
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def cleanup_db():
    """Cleanup database connections"""
    engine.dispose()

def check_db_connection():
    """Check database connection"""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        return True
    except OperationalError as e:
        logger.error(f"Database connection failed: {str(e)}")
        return False
    finally:
        db.close()

def init_db():
    """Initialize database with default data"""
    db = SessionLocal()
    try:
        # Create default tracks
        default_tracks = [
            Track(
                title="Deep Focus ASMR",
                artist="ASMR Artist",
                duration=180.0,
                audio_url="/assets/audio/deep_focus.mp3",
                cover_url="/assets/images/deep_focus.jpg"
            ),
            Track(
                title="Rain Sounds",
                artist="Nature Sounds",
                duration=240.0,
                audio_url="/assets/audio/rain.mp3",
                cover_url="/assets/images/rain.jpg"
            ),
            Track(
                title="Ocean Waves",
                artist="Nature Sounds",
                duration=300.0,
                audio_url="/assets/audio/ocean.mp3",
                cover_url="/assets/images/ocean.jpg"
            ),
            Track(
                title="Soft Piano",
                artist="Classical ASMR",
                duration=210.0,
                audio_url="/assets/audio/piano.mp3",
                cover_url="/assets/images/piano.jpg"
            ),
            Track(
                title="Forest Ambience",
                artist="Nature Sounds",
                duration=270.0,
                audio_url="/assets/audio/forest.mp3",
                cover_url="/assets/images/forest.jpg"
            ),
        ]

        # Add tracks if they don't exist
        for track in default_tracks:
            existing_track = db.query(Track).filter_by(
                title=track.title,
                artist=track.artist
            ).first()
            if not existing_track:
                db.add(track)

        # Create default playlists
        nature_playlist = Playlist(
            name="Nature Sounds",
            description="Relaxing nature sounds for focus and meditation",
            cover_url="/assets/images/nature.jpg",
            user_id=1  # Admin user
        )
        focus_playlist = Playlist(
            name="Deep Focus",
            description="ASMR sounds for concentration and study",
            cover_url="/assets/images/focus.jpg",
            user_id=1  # Admin user
        )

        # Add playlists if they don't exist
        existing_nature = db.query(Playlist).filter_by(name="Nature Sounds").first()
        if not existing_nature:
            db.add(nature_playlist)
            # Add nature tracks to playlist
            nature_playlist.tracks.extend([
                track for track in default_tracks 
                if track.artist == "Nature Sounds"
            ])

        existing_focus = db.query(Playlist).filter_by(name="Deep Focus").first()
        if not existing_focus:
            db.add(focus_playlist)
            # Add focus tracks to playlist
            focus_playlist.tracks.extend([
                track for track in default_tracks 
                if track.artist in ["ASMR Artist", "Classical ASMR"]
            ])

        db.commit()
        logger.info("Default audio content added successfully")

    except Exception as e:
        logger.error(f"Error initializing database: {str(e)}")
        db.rollback()
        raise
    finally:
        db.close()

def startup():
    """Application startup tasks"""
    Base.metadata.create_all(bind=engine)
    init_db()
