from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import health, exercises, sessions, rooms, streaming_ws
from app.config import get_settings

settings = get_settings()

app = FastAPI(
    title="PronounceAI Backend & Real-time Scoring API",
    description="Real-time WebRTC audio streaming, phoneme alignment, and speech scoring platform powered by LiveKit and FastAPI.",
    version="1.0.0"
)

# Enable CORS for Flutter app (Web, mobile, desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api")
app.include_router(exercises.router, prefix="/api")
app.include_router(sessions.router, prefix="/api")
# Tech stack spec route: GET /api/v1/rooms/join-token
app.include_router(rooms.router, prefix="/api")
# Direct real-time WebSocket audio streaming fallback
app.include_router(streaming_ws.router, prefix="/api")

@app.get("/")
def root():
    return {
        "message": "PronounceAI Real-Time Voice Assessment Backend is running.",
        "docs": "/docs",
        "livekit_url": settings.LIVEKIT_URL
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)
