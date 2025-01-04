from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import JSONResponse, StreamingResponse
from typing import List, Dict, Optional
import logging
from ..auth.auth import get_current_user
from ..models.database import User
from ..services.tts_service import TTSService
from sqlalchemy.orm import Session
from ..database import get_db
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
    "Content-Type": "application/json",
}

# TTS service instance
tts_service = TTSService()

@router.get("/voices")
async def get_voices(
    current_user: User = Depends(get_current_user)
):
    try:
        logger.info(f"Getting available voices for user {current_user.username}")
        
        voices = await tts_service.get_voices()
        
        return JSONResponse(
            content={"voices": voices},
            headers=CORS_HEADERS
        )

    except Exception as e:
        logger.error(f"Error getting voices: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "获取语音列表失败"},
            headers=CORS_HEADERS
        )

@router.post("/generate")
async def generate_speech(
    request: Request,
    current_user: User = Depends(get_current_user)
):
    try:
        logger.info(f"Processing TTS request for user {current_user.username}")
        
        # Parse request body
        body = await request.json()
        logger.info(f"Request body: {body}")

        # Validate required fields
        text = body.get("text")
        voice_id = body.get("voice_id")

        if not text:
            return JSONResponse(
                status_code=400,
                content={"detail": "文本内容不能为空"},
                headers=CORS_HEADERS
            )

        if not voice_id:
            return JSONResponse(
                status_code=400,
                content={"detail": "必须指定语音ID"},
                headers=CORS_HEADERS
            )

        # Validate text length
        if len(text) > 5000:
            return JSONResponse(
                status_code=400,
                content={"detail": "文本内容不能超过5000个字符"},
                headers=CORS_HEADERS
            )

        # Validate optional parameters
        speed = body.get("speed", 1.0)
        pitch = body.get("pitch", 1.0)

        if not isinstance(speed, (int, float)) or speed < 0.5 or speed > 2.0:
            return JSONResponse(
                status_code=400,
                content={"detail": "语速必须是0.5到2.0之间的数值"},
                headers=CORS_HEADERS
            )

        if not isinstance(pitch, (int, float)) or pitch < 0.5 or pitch > 2.0:
            return JSONResponse(
                status_code=400,
                content={"detail": "音调必须是0.5到2.0之间的数值"},
                headers=CORS_HEADERS
            )

        # Check if voice_id is valid
        available_voices = await tts_service.get_voices()
        if voice_id not in [v["id"] for v in available_voices]:
            return JSONResponse(
                status_code=400,
                content={"detail": "无效的语音ID"},
                headers=CORS_HEADERS
            )

        # Generate speech
        try:
            audio_data = await tts_service.generate_speech(
                text=text,
                voice_id=voice_id,
                speed=speed,
                pitch=pitch
            )
            
            # Create in-memory file-like object
            audio_stream = io.BytesIO(audio_data)
            
            # Return audio file
            return StreamingResponse(
                audio_stream,
                media_type="audio/mp3",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Content-Disposition": "attachment; filename=speech.mp3"
                }
            )

        except Exception as e:
            logger.error(f"TTS service error: {str(e)}", exc_info=True)
            return JSONResponse(
                status_code=500,
                content={"detail": "语音生成服务暂时不可用"},
                headers=CORS_HEADERS
            )

    except Exception as e:
        logger.error(f"Error processing TTS request: {str(e)}", exc_info=True)
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
