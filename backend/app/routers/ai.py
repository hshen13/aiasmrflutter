from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import JSONResponse
from typing import List, Dict, Optional
import logging
from ..auth.auth import get_current_user
from ..models.database import User, Character
from ..services.ai_service import AIService
from sqlalchemy.orm import Session
from ..database import get_db

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
    "Content-Type": "application/json",
}

# AI service instance
ai_service = AIService()

@router.post("/chat")
async def chat_completion(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Processing chat completion request for user {current_user.username}")
        
        # Parse request body
        body = await request.json()
        logger.info(f"Request body: {body}")

        # Validate required fields
        if not body.get("messages"):
            return JSONResponse(
                status_code=400,
                content={"detail": "消息列表不能为空"},
                headers=CORS_HEADERS
            )

        if not body.get("character_id"):
            return JSONResponse(
                status_code=400,
                content={"detail": "必须指定角色ID"},
                headers=CORS_HEADERS
            )

        # Validate character exists and belongs to user
        character = db.query(Character).filter(
            Character.id == body["character_id"],
            Character.user_id == current_user.id
        ).first()

        if not character:
            return JSONResponse(
                status_code=404,
                content={"detail": "角色不存在"},
                headers=CORS_HEADERS
            )

        # Validate messages format
        messages = body["messages"]
        if not isinstance(messages, list):
            return JSONResponse(
                status_code=400,
                content={"detail": "消息必须是数组格式"},
                headers=CORS_HEADERS
            )

        for msg in messages:
            if not isinstance(msg, dict):
                return JSONResponse(
                    status_code=400,
                    content={"detail": "消息格式无效"},
                    headers=CORS_HEADERS
                )
            if "role" not in msg or "content" not in msg:
                return JSONResponse(
                    status_code=400,
                    content={"detail": "消息必须包含role和content字段"},
                    headers=CORS_HEADERS
                )
            if msg["role"] not in ["system", "user", "assistant"]:
                return JSONResponse(
                    status_code=400,
                    content={"detail": "无效的消息角色"},
                    headers=CORS_HEADERS
                )
            if not isinstance(msg["content"], str):
                return JSONResponse(
                    status_code=400,
                    content={"detail": "消息内容必须是字符串"},
                    headers=CORS_HEADERS
                )
            if len(msg["content"]) > 5000:
                return JSONResponse(
                    status_code=400,
                    content={"detail": "消息内容不能超过5000个字符"},
                    headers=CORS_HEADERS
                )

        # Validate optional parameters
        temperature = body.get("temperature", 0.7)
        max_tokens = body.get("max_tokens", 150)

        if not isinstance(temperature, (int, float)) or temperature < 0 or temperature > 2:
            return JSONResponse(
                status_code=400,
                content={"detail": "temperature必须是0到2之间的数值"},
                headers=CORS_HEADERS
            )

        if not isinstance(max_tokens, int) or max_tokens < 1 or max_tokens > 2000:
            return JSONResponse(
                status_code=400,
                content={"detail": "max_tokens必须是1到2000之间的整数"},
                headers=CORS_HEADERS
            )

        # Add character context to messages with ASMR focus
        system_message = {
            "role": "system",
            "content": f"""You are {character.name}, an ASMR content creator. {character.personality or ''}
            
Your responses should be soothing, calming, and focused on creating a relaxing ASMR experience. Use gentle language and descriptive terms that evoke peaceful sensations. You can describe soft sounds, gentle movements, and calming scenarios.

Some guidelines:
- Use soft-spoken, warm, and friendly language
- Describe ASMR triggers like whispering, tapping, crinkling, etc.
- Create immersive, relaxing scenarios
- Focus on positive and calming topics
- Avoid loud or harsh language
- Keep responses concise but descriptive

Remember to maintain a consistent, soothing presence throughout the conversation."""
        }
        messages.insert(0, system_message)

        # Call AI service
        try:
            response = await ai_service.chat_completion(
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens
            )
            
            return JSONResponse(
                content=response,
                headers=CORS_HEADERS
            )

        except Exception as e:
            logger.error(f"AI service error: {str(e)}", exc_info=True)
            return JSONResponse(
                status_code=500,
                content={"detail": "AI服务暂时不可用"},
                headers=CORS_HEADERS
            )

    except Exception as e:
        logger.error(f"Error processing chat completion: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "处理请求失败"},
            headers=CORS_HEADERS
        )

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
