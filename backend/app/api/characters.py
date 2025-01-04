from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from ..models.database import Character, User
from ..schemas.character import CharacterCreate, CharacterResponse
from ..database import get_db
from ..auth.auth import get_current_user_optional

router = APIRouter()

@router.get("", response_model=List[CharacterResponse])
async def get_characters(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Get all characters"""
    characters = db.query(Character).all()
    return characters

@router.post("", response_model=CharacterResponse, status_code=201)
async def create_character(
    character: CharacterCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_optional),
):
    """Create a new character"""
    if not current_user:
        raise HTTPException(
            status_code=401,
            detail="Authentication required to create characters"
        )

    db_character = Character(
        name=character.name,
        description=character.description,
        system_prompt=character.system_prompt,
        image_url=character.image_url,
        creator_id=current_user.id,
    )
    db.add(db_character)
    db.commit()
    db.refresh(db_character)
    return db_character

@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(
    character_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific character by ID"""
    character = db.query(Character).filter(Character.id == character_id).first()
    if not character:
        raise HTTPException(status_code=404, detail="Character not found")
    return character

@router.delete("/{character_id}")
async def delete_character(
    character_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_optional),
):
    """Delete a character"""
    if not current_user:
        raise HTTPException(
            status_code=401,
            detail="Authentication required to delete characters"
        )

    character = db.query(Character).filter(Character.id == character_id).first()
    if not character:
        raise HTTPException(status_code=404, detail="Character not found")

    if character.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this character")

    db.delete(character)
    db.commit()
    return {"message": "Character deleted"}
