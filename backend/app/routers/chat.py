from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import JSONResponse, StreamingResponse
from typing import List, Optional
import logging
from pathlib import Path
from ..auth.auth import get_current_user
from ..models.database import Chat, Message, User, Character, generate_uuid
from ..schemas.chat import (
    ChatCreate, ChatUpdate, ChatResponse, MessageCreate, 
    MessageResponse, MessagesResponse, ChatListResponse
)
from sqlalchemy.orm import Session
from ..database import get_db
from datetime import datetime
from ..services.ai_service import AIService
import io

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

router = APIRouter()

# CORS headers
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Max-Age": "3600",
}

# Message type validation
VALID_MESSAGE_TYPES = {"text", "audio"}

@router.get("", response_model=ChatListResponse)
async def get_chats(
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Getting chats for user {current_user.username}")
        
        if page < 1 or limit < 1 or limit > 100:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters")

        query = db.query(Chat).filter(Chat.user_id == current_user.id)
        if search:
            query = query.filter(Chat.title.ilike(f"%{search}%"))

        total = query.count()
        chats = query.order_by(Chat.updated_at.desc()).offset((page - 1) * limit).limit(limit).all()

        chat_list = []
        for chat in chats:
            response_data = chat.to_dict()
            if response_data["character"]:
                response_data["character"]["id"] = str(response_data["character"]["id"])
                response_data["character"]["user_id"] = str(response_data["character"]["user_id"])
                response_data["character"]["creator_id"] = str(response_data["character"]["creator_id"])
            if response_data["last_message"]:
                response_data["last_message"]["id"] = str(response_data["last_message"]["id"])
                response_data["last_message"]["chat_id"] = str(response_data["last_message"]["chat_id"])
                response_data["last_message"]["is_user"] = response_data["last_message"].pop("is_from_user")
            chat_list.append(response_data)

        return {
            "items": chat_list,
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit
        }

    except Exception as e:
        logger.error(f"Error getting chats: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to get chat list")

@router.post("", response_model=ChatResponse)
async def create_chat(
    chat: ChatCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        character = db.query(Character).filter(Character.id == chat.character_id).first()
        if not character:
            raise HTTPException(status_code=404, detail="Character not found")

        # Ensure title is never null since it's non-nullable in the database
        title = character.name if not chat.title else chat.title
        description = character.description if not chat.description else chat.description

        if len(title) > 100:
            raise HTTPException(status_code=400, detail="Title too long")
        if description and len(description) > 500:
            raise HTTPException(status_code=400, detail="Description too long")

        db_chat = Chat(
            user_id=current_user.id,
            character_id=character.id,
            title=title,
            description=description,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        db.add(db_chat)
        db.commit()
        db.refresh(db_chat)

        # Create welcome message
        ai_service = AIService()
        welcome_response = await ai_service.process_message(
            "Hello",
            character.name,
            character.system_prompt,
            []
        )

        # Create welcome message with audio
        audio_filename = None
        if welcome_response["audio"]:
            # Save audio to file with absolute path
            audio_filename = f"message_{generate_uuid()}.mp3"
            audio_base_dir = Path("/app/backend/static/audio")
            audio_base_dir.mkdir(parents=True, exist_ok=True)
            audio_path = audio_base_dir / audio_filename
            audio_path.write_bytes(welcome_response["audio"])
            logger.info(f"Saved audio file to {audio_path}")

        welcome_message = Message(
            chat_id=db_chat.id,
            content=welcome_response["text"],
            type="text",
            is_from_user=False,
            created_at=datetime.utcnow(),
            media_url=f"/static/audio/{audio_filename}" if audio_filename else '',  # Use empty string instead of None
            duration=0.0,
            thumbnail_url=''
        )
        db.add(welcome_message)
        db.commit()

        response_data = db_chat.to_dict()
        if response_data["character"]:
            response_data["character"]["id"] = str(response_data["character"]["id"])
            response_data["character"]["user_id"] = str(response_data["character"]["user_id"])
            response_data["character"]["creator_id"] = str(response_data["character"]["creator_id"])

        return response_data

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating chat: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to create chat")

@router.post("/{chat_id}/messages", response_model=MessagesResponse)
async def create_message(
    chat_id: str,
    message: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        if not message.content or len(message.content) > 5000:
            raise HTTPException(status_code=400, detail="Invalid message content")

        if message.type not in VALID_MESSAGE_TYPES:
            raise HTTPException(status_code=400, detail="Invalid message type")

        chat = db.query(Chat).filter(
            Chat.id == chat_id,
            Chat.user_id == current_user.id
        ).first()
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")

        character = chat.character
        if not character:
            raise HTTPException(status_code=404, detail="Character not found")

        # Get previous messages for context
        previous_messages = db.query(Message).filter(
            Message.chat_id == chat_id
        ).order_by(Message.created_at.asc()).all()
        
        # Build context messages with proper ordering
        context_messages = []
        for prev_msg in previous_messages:
            # Skip system messages or messages without content
            if not prev_msg.content:
                continue
                
            context_messages.append({
                "role": "user" if prev_msg.is_from_user else "assistant",
                "content": prev_msg.content
            })
            logger.info(f"Added message to context - Role: {'user' if prev_msg.is_from_user else 'assistant'}, Content: {prev_msg.content[:50]}...")

        # Increment character interaction count
        character.interactions += 1
        db.commit()

        # Create user message
        user_message = Message(
            chat_id=chat_id,
            content=message.content,
            type=message.type,
            is_from_user=True,
            created_at=datetime.utcnow()
        )
        db.add(user_message)
        
        # Get AI response with audio
        ai_service = AIService()
        response = await ai_service.process_message(
            message.content,
            character.name,
            character.system_prompt,
            context_messages
        )

        # Create AI response message with audio
        audio_filename = None
        if response["audio"]:
            # Save audio to file with absolute path
            audio_filename = f"message_{generate_uuid()}.mp3"
            audio_base_dir = Path("/app/backend/static/audio")
            audio_base_dir.mkdir(parents=True, exist_ok=True)
            audio_path = audio_base_dir / audio_filename
            audio_path.write_bytes(response["audio"])
            logger.info(f"Saved audio file to {audio_path}")

        ai_message = Message(
            chat_id=chat_id,
            content=response["text"],
            type="text",
            is_from_user=False,
            created_at=datetime.utcnow(),
            media_url=f"/static/audio/{audio_filename}" if audio_filename else '',  # Use empty string instead of None
            duration=0.0,
            thumbnail_url=''
        )
        db.add(ai_message)

        # Update chat timestamp
        chat.updated_at = datetime.utcnow()
        db.commit()

        # Return both messages
        return {
            "messages": [
                {
                    **user_message.to_dict(),
                    "is_user": user_message.is_from_user
                },
                {
                    **ai_message.to_dict(),
                    "is_user": ai_message.is_from_user
                }
            ]
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating message: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to process message")

@router.get("/{chat_id}/messages/{message_id}/audio")
async def get_message_audio(
    chat_id: str,
    message_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Verify chat belongs to user
        chat = db.query(Chat).filter(
            Chat.id == chat_id,
            Chat.user_id == current_user.id
        ).first()
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")

        # Get message
        message = db.query(Message).filter(
            Message.id == message_id,
            Message.chat_id == chat_id,
            Message.is_from_user == False
        ).first()
        if not message:
            raise HTTPException(status_code=404, detail="Message not found")

        # Generate audio
        ai_service = AIService()
        audio_content = await ai_service.text_to_speech(
            message.content,
            cache_key=f"message_{message_id}"
        )

        return StreamingResponse(
            io.BytesIO(audio_content),
            media_type="audio/mpeg",
            headers={
                **CORS_HEADERS,
                "Content-Disposition": f'attachment; filename="message_{message_id}.mp3"'
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting message audio: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to get audio")

@router.get("/{chat_id}/messages", response_model=MessagesResponse)
async def get_messages(
    chat_id: str,
    page: int = 1,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Verify chat belongs to user
        chat = db.query(Chat).filter(
            Chat.id == chat_id,
            Chat.user_id == current_user.id
        ).first()
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")

        # Get messages with pagination
        messages = db.query(Message).filter(
            Message.chat_id == chat_id
        ).order_by(Message.created_at.asc()).offset((page - 1) * limit).limit(limit).all()

        return {
            "messages": [
                {
                    **message.to_dict(),
                    "is_user": message.is_from_user
                }
                for message in messages
            ]
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting messages: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to get messages")

@router.options("/{path:path}")
async def options_handler(request: Request):
    requested_headers = request.headers.get('access-control-request-headers', '')
    requested_method = request.headers.get('access-control-request-method', '')
    
    headers = {
        **CORS_HEADERS,
        "Access-Control-Allow-Headers": requested_headers or CORS_HEADERS["Access-Control-Allow-Headers"],
        "Access-Control-Allow-Methods": requested_method or CORS_HEADERS["Access-Control-Allow-Methods"],
    }
    
    return Response(
        content="",
        status_code=204,
        headers=headers
    )
