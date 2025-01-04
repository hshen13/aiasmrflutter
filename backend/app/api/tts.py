from fastapi import APIRouter, Response
from ..services.tts_service import synthesize_text

router = APIRouter()

@router.post("/tts")
def text_to_speech(payload: dict):
    text = payload.get("text", "")
    audio_data = synthesize_text(text)
    return Response(content=audio_data, media_type="audio/mpeg")
