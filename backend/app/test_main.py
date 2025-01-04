from fastapi.testclient import TestClient
from .main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello, AI ASMR Helper!"}

def test_chat_endpoint():
    response = client.post("/api/chat", json={"prompt": "test message"})
    assert response.status_code == 200
    assert "answer" in response.json()

def test_tts_endpoint():
    response = client.post("/api/tts", json={"text": "test message"})
    assert response.status_code == 200
    assert response.headers["content-type"] == "audio/mpeg"
