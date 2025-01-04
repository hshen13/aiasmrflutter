from fastapi import APIRouter, Depends, HTTPException, status, Response
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session, joinedload
from typing import List
import os
from ..database import get_db
from ..auth.auth import get_current_user
from ..models.database import User, Track as TrackModel, Playlist as PlaylistModel, RecentlyPlayed as RecentlyPlayedModel
from ..schemas.audio import (
    Track, TrackCreate, 
    Playlist, PlaylistCreate, PlaylistUpdate, PlaylistAddTrack, PlaylistRemoveTrack,
    RecentlyPlayed, RecentlyPlayedCreate,
    AudioResponse
)
from datetime import datetime
from sqlalchemy import desc
from pydantic import BaseModel

class UpdateDuration(BaseModel):
    duration: float

router = APIRouter()

@router.patch("/tracks/{track_id}/duration", response_model=Track)
async def update_track_duration(
    track_id: str,
    duration_update: UpdateDuration,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update track duration"""
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        track.duration = duration_update.duration
        track.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(track)
        return Track.from_orm(track)
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in update_track_duration: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update track duration: {str(e)}"
        )

@router.get("/stream/{track_id}")
async def stream_audio(
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Stream audio file"""
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        # Get the base directory and construct full path
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        audio_path = os.path.join(base_dir, "static", "audio", track.audio_url)
        
        print(f"Base directory: {base_dir}")
        print(f"Audio URL from track: {track.audio_url}")
        print(f"Full audio path: {audio_path}")
        print(f"File exists: {os.path.exists(audio_path)}")
        
        if not os.path.exists(audio_path):
            raise HTTPException(status_code=404, detail=f"Audio file not found at {audio_path}")
        
        # Add recently played entry
        recently_played = RecentlyPlayedModel(
            user_id=current_user.id,
            track_id=track_id,
            played_at=datetime.utcnow()
        )
        db.add(recently_played)
        db.commit()
        
        return FileResponse(
            audio_path,
            media_type="audio/mpeg",
            filename=f"{track.title}.mp3",
            headers={
                "Accept-Ranges": "bytes",
                "Cache-Control": "public, max-age=3600",
            }
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in stream_audio: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to stream audio: {str(e)}"
        )

# Track endpoints
@router.get("/tracks", response_model=List[Track])
async def get_tracks(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        tracks = db.query(TrackModel).options(
            joinedload(TrackModel.user)
        ).offset(skip).limit(limit).all()
        return [Track.from_orm(track) for track in tracks]
    except Exception as e:
        print(f"Error in get_tracks: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch tracks: {str(e)}"
        )

@router.get("/favorites", response_model=List[Track])
async def get_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        user = db.query(User).filter(
            User.id == current_user.id
        ).options(
            joinedload(User.favorite_tracks).joinedload(TrackModel.user)
        ).first()
        return [Track.from_orm(track) for track in user.favorite_tracks]
    except Exception as e:
        print(f"Error in get_favorites: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch favorites: {str(e)}"
        )

@router.post("/favorites/{track_id}")
async def add_to_favorites(
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        user = db.query(User).filter(
            User.id == current_user.id
        ).options(
            joinedload(User.favorite_tracks)
        ).first()
        if track not in user.favorite_tracks:
            user.favorite_tracks.append(track)
            db.commit()
        return {"message": "Track added to favorites"}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in add_to_favorites: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to add track to favorites: {str(e)}"
        )

@router.delete("/favorites/{track_id}")
async def remove_from_favorites(
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        user = db.query(User).filter(
            User.id == current_user.id
        ).options(
            joinedload(User.favorite_tracks)
        ).first()
        if track in user.favorite_tracks:
            user.favorite_tracks.remove(track)
            db.commit()
        return {"message": "Track removed from favorites"}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in remove_from_favorites: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to remove track from favorites: {str(e)}"
        )

@router.get("/tracks/{track_id}", response_model=Track)
async def get_track(
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        return Track.from_orm(track)
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in get_track: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch track: {str(e)}"
        )

@router.post("/tracks/play/{track_id}", response_model=RecentlyPlayed)
async def play_track(
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        recently_played = RecentlyPlayedModel(
            user_id=current_user.id,
            track_id=track_id,
            played_at=datetime.utcnow()
        )
        db.add(recently_played)
        db.commit()
        db.refresh(recently_played)
        
        # Reload with track and user relationships
        recently_played = db.query(RecentlyPlayedModel).filter(
            RecentlyPlayedModel.id == recently_played.id
        ).options(
            joinedload(RecentlyPlayedModel.track).joinedload(TrackModel.user)
        ).first()
        return RecentlyPlayed(
            id=recently_played.id,
            user_id=recently_played.user_id,
            track_id=recently_played.track_id,
            played_at=recently_played.played_at,
            track=Track.from_orm(recently_played.track)
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in play_track: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to play track: {str(e)}"
        )

# Playlist endpoints
@router.get("/playlists")
async def get_playlists(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        playlists = db.query(PlaylistModel).filter(
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).all()
        
        # Convert to response format using to_dict()
        return [playlist.to_dict() for playlist in playlists]
    except Exception as e:
        print(f"Error in get_playlists: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch playlists: {str(e)}"
        )

@router.get("/playlists/{playlist_id}")
async def get_playlist(
    playlist_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        playlist = db.query(PlaylistModel).filter(
            PlaylistModel.id == playlist_id,
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).first()
        if not playlist:
            raise HTTPException(status_code=404, detail="Playlist not found")
        return playlist.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in get_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch playlist: {str(e)}"
        )

@router.post("/playlists")
async def create_playlist(
    playlist: PlaylistCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        db_playlist = PlaylistModel(**playlist.dict(), user_id=current_user.id)
        db.add(db_playlist)
        db.commit()
        db.refresh(db_playlist)
        return db_playlist.to_dict()
    except Exception as e:
        print(f"Error in create_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create playlist: {str(e)}"
        )

@router.put("/playlists/{playlist_id}")
async def update_playlist(
    playlist_id: str,
    playlist_update: PlaylistUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        db_playlist = db.query(PlaylistModel).filter(
            PlaylistModel.id == playlist_id,
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).first()
        if not db_playlist:
            raise HTTPException(status_code=404, detail="Playlist not found")
        
        for key, value in playlist_update.dict(exclude_unset=True).items():
            setattr(db_playlist, key, value)
        
        db.commit()
        db.refresh(db_playlist)
        return db_playlist.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in update_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update playlist: {str(e)}"
        )

@router.post("/playlists/{playlist_id}/tracks")
async def add_track_to_playlist(
    playlist_id: str,
    track_data: PlaylistAddTrack,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        playlist = db.query(PlaylistModel).filter(
            PlaylistModel.id == playlist_id,
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).first()
        if not playlist:
            raise HTTPException(status_code=404, detail="Playlist not found")
        
        track = db.query(TrackModel).filter(
            TrackModel.id == track_data.track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        playlist.tracks.append(track)
        db.commit()
        db.refresh(playlist)
        return playlist.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in add_track_to_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to add track to playlist: {str(e)}"
        )

@router.delete("/playlists/{playlist_id}/tracks/{track_id}")
async def remove_track_from_playlist(
    playlist_id: str,
    track_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        playlist = db.query(PlaylistModel).filter(
            PlaylistModel.id == playlist_id,
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).first()
        if not playlist:
            raise HTTPException(status_code=404, detail="Playlist not found")
        
        track = db.query(TrackModel).filter(
            TrackModel.id == track_id
        ).options(
            joinedload(TrackModel.user)
        ).first()
        if not track:
            raise HTTPException(status_code=404, detail="Track not found")
        
        playlist.tracks.remove(track)
        db.commit()
        db.refresh(playlist)
        return playlist.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in remove_track_from_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to remove track from playlist: {str(e)}"
        )

@router.delete("/playlists/{playlist_id}", response_model=AudioResponse)
async def delete_playlist(
    playlist_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        playlist = db.query(PlaylistModel).filter(
            PlaylistModel.id == playlist_id,
            PlaylistModel.user_id == current_user.id
        ).options(
            joinedload(PlaylistModel.user),
            joinedload(PlaylistModel.tracks)
        ).first()
        if not playlist:
            raise HTTPException(status_code=404, detail="Playlist not found")
        
        db.delete(playlist)
        db.commit()
        return AudioResponse(success=True, message="Playlist deleted successfully")
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in delete_playlist: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete playlist: {str(e)}"
        )

# Recently played endpoints
@router.get("/recently-played", response_model=List[RecentlyPlayed])
async def get_recently_played(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        recently_played = db.query(RecentlyPlayedModel).filter(
            RecentlyPlayedModel.user_id == current_user.id
        ).options(
            joinedload(RecentlyPlayedModel.track).joinedload(TrackModel.user)
        ).order_by(desc(RecentlyPlayedModel.played_at)).limit(limit).all()
        
        return [
            RecentlyPlayed(
                id=item.id,
                user_id=item.user_id,
                track_id=item.track_id,
                played_at=item.played_at,
                track=Track.from_orm(item.track)
            ) for item in recently_played
        ]
    except Exception as e:
        print(f"Error in get_recently_played: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch recently played: {str(e)}"
        )
