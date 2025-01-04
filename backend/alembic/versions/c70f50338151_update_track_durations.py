"""update track durations

Revision ID: c70f50338151
Revises: 002_make_chat_title_nullable
Create Date: 2024-01-10 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import Session
import os
from app.utils.media_converter import get_audio_duration

# revision identifiers, used by Alembic.
revision = 'c70f50338151'
down_revision = '002_make_chat_title_nullable'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Get base directory for audio files
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    static_dir = os.path.join(base_dir, "static", "audio")

    # Create a connection and bind it to a session
    connection = op.get_bind()
    session = Session(bind=connection)

    try:
        # Get all tracks
        tracks = connection.execute(sa.text('SELECT id, audio_url, duration FROM track'))
        
        # Update duration for each track
        for track in tracks:
            audio_path = os.path.join(static_dir, track.audio_url)
            if os.path.exists(audio_path):
                actual_duration = get_audio_duration(audio_path)
                if actual_duration != track.duration:
                    connection.execute(
                        sa.text('UPDATE track SET duration = :duration WHERE id = :id'),
                        {'duration': actual_duration, 'id': track.id}
                    )
        
        session.commit()
    except Exception as e:
        session.rollback()
        raise e
    finally:
        session.close()

def downgrade() -> None:
    # No downgrade needed as we're just updating durations to their actual values
    pass
