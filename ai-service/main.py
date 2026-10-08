import os

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="AI Service", version="0.1.0")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:3b")


class ChatRequest(BaseModel):
    prompt: str


@app.get("/health")
async def health():
    return {"status": "UP"}


@app.post("/chat")
async def chat(request: ChatRequest):
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": request.prompt,
        "stream": False,
    }

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{OLLAMA_URL}/api/generate",
                json=payload,
            )
            response.raise_for_status()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Could not reach Ollama: {exc}") from exc

    data = response.json()
    return {
        "model": data.get("model", OLLAMA_MODEL),
        "response": data.get("response", ""),
    }
