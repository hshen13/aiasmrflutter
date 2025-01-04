from fastapi import APIRouter
from ..services.ai_service import get_ai_response

router = APIRouter()

@router.post("/chat")
def chat_with_ai(payload: dict):
    prompt = payload.get("prompt", "")
    ai_answer = get_ai_response(prompt)
    return {"answer": ai_answer}
