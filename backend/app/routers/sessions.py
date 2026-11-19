import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from app.config import get_settings
from app.services.livekit_token import create_room_token
from app.services.stt_alignment import PhonemeAlignmentService
from app.services.scoring_engine import ScoringEngine

router = APIRouter(prefix="/sessions", tags=["Sessions"])

settings = get_settings()
alignment_service = PhonemeAlignmentService(engine=settings.ALIGNMENT_ENGINE)
scoring_engine = ScoringEngine()

class SessionTokenRequest(BaseModel):
    room_name: Optional[str] = None
    participant_name: Optional[str] = "Student"
    exercise_id: Optional[str] = "ex-1"

class SessionTokenResponse(BaseModel):
    token: str
    room_name: str
    livekit_url: str
    participant_identity: str

class ManualEvaluationRequest(BaseModel):
    target_sentence: str
    # In real app, could accept base64 or audio file upload
    simulated_speech: bool = True

@router.post("/token", response_model=SessionTokenResponse)
def get_session_token(req: SessionTokenRequest):
    """
    Issues a LiveKit JWT token for the Flutter client to join the SFU room
    and stream WebRTC audio.
    """
    room = req.room_name or f"practice-room-{uuid.uuid4().hex[:8]}"
    identity = f"user-{uuid.uuid4().hex[:6]}"

    try:
        jwt_token = create_room_token(
            room_name=room,
            participant_identity=identity,
            participant_name=req.participant_name or "Student"
        )
        return SessionTokenResponse(
            token=jwt_token,
            room_name=room,
            livekit_url=settings.LIVEKIT_URL,
            participant_identity=identity
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate LiveKit token: {str(e)}")

@router.post("/evaluate")
async def evaluate_sentence(req: ManualEvaluationRequest):
    """
    Direct evaluation endpoint for REST-based fallbacks or test fixtures.
    """
    alignment = alignment_service.process_pcm_audio(
        audio_bytes=b"sample_mock_audio_bytes" * 500,
        target_sentence=req.target_sentence
    )
    feedback = await scoring_engine.evaluate_async(alignment, reference_text=req.target_sentence)
    return feedback
