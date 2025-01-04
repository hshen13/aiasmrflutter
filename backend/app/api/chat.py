from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from ..models.database import Chat, Message, Character, User
from ..schemas.chat import ChatCreate, ChatResponse, MessageCreate, MessageResponse
from ..database import get_db
from ..auth.auth import get_current_user_optional
from ..services.ai_service import generate_response
from ..services.tts_service import generate_audio

router = APIRouter()

@router.post("/chats", response_model=ChatResponse, status_code=201)
async def create_chat(
    character_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    try:
        # Check if character exists
        character = db.query(Character).filter(Character.id == character_id).first()
        if not character:
            raise HTTPException(status_code=404, detail="Character not found")

        # Create new chat
        chat = Chat(
            user_id=current_user.id if current_user else None,
            character_id=character_id
        )
        db.add(chat)
        db.commit()
        db.refresh(chat)

        # Increment character interactions
        character.interactions += 1
        db.commit()

        # Create welcome message
        welcome_message = Message(
            chat_id=chat.id,
            content=f"你好，我是{character.name}。{character.description}",
            is_user=False
        )
        db.add(welcome_message)
        db.commit()
        db.refresh(welcome_message)

        # Generate audio for welcome message
        try:
            audio_url = await generate_audio(welcome_message.content)
            welcome_message.audio_url = audio_url
            db.commit()
        except Exception as e:
            print(f"Failed to generate audio: {e}")

        return {
            "id": chat.id,
            "character": character,
            "last_message": welcome_message.content,
            "last_message_at": welcome_message.created_at,
        }
    except Exception as e:
        db.rollback()
        print(f"Error creating chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/chats", response_model=List[ChatResponse])
async def get_chats(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    if not current_user:
        return []

    chats = db.query(Chat).filter(Chat.user_id == current_user.id).all()
    
    chat_responses = []
    for chat in chats:
        # Get last message
        last_message = (
            db.query(Message)
            .filter(Message.chat_id == chat.id)
            .order_by(Message.created_at.desc())
            .first()
        )
        
        chat_responses.append({
            "id": chat.id,
            "character": chat.character,
            "last_message": last_message.content if last_message else None,
            "last_message_at": last_message.created_at if last_message else chat.created_at,
        })
    
    return chat_responses

@router.get("/chats/{chat_id}/messages", response_model=List[MessageResponse])
async def get_chat_messages(
    chat_id: int,
    db: Session = Depends(get_db),
):
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    messages = (
        db.query(Message)
        .filter(Message.chat_id == chat_id)
        .order_by(Message.created_at.asc())
        .all()
    )
    return messages

@router.post("/chats/{chat_id}/messages", response_model=MessageResponse, status_code=201)
async def create_message(
    chat_id: int,
    message: MessageCreate,
    db: Session = Depends(get_db),
):
    try:
        # Check if chat exists
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")

        # Create user message
        user_message = Message(
            chat_id=chat_id,
            content=message.content,
            is_user=True
        )
        db.add(user_message)
        db.commit()

        # Generate AI response
        character = chat.character
        response_text = await generate_response(
            character.system_prompt,
            message.content
        )

        # Create AI message
        ai_message = Message(
            chat_id=chat_id,
            content=response_text,
            is_user=False
        )
        db.add(ai_message)
        db.commit()
        db.refresh(ai_message)

        # Generate audio for AI response
        try:
            audio_url = await generate_audio(response_text)
            ai_message.audio_url = audio_url
            db.commit()
        except Exception as e:
            print(f"Failed to generate audio: {e}")

        return ai_message
    except Exception as e:
        db.rollback()
        print(f"Error creating message: {e}")
        raise HTTPException(status_code=500, detail=str(e))
