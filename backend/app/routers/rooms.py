import uuid
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from pydantic import BaseModel

from app.config import get_settings
from app.services.livekit_token import create_room_token

router = APIRouter(prefix="/v1/rooms", tags=["Rooms & Streaming Tokens"])
settings = get_settings()

class JoinTokenResponse(BaseModel):
    token: str
    room_name: str
    livekit_url: str
    participant_identity: str

@router.get("/join-token", response_model=JoinTokenResponse)
def get_join_token(
    room_name: Optional[str] = Query(default=None, description="Optional room identifier"),
    identity: Optional[str] = Query(default=None, description="Client identity"),
    name: Optional[str] = Query(default="Student", description="Display name of the learner")
):
    """
    Recommended Endpoint from Tech Stack Spec:
    GET /api/v1/rooms/join-token

    Generates an ephemeral, cryptographically signed LiveKit JWT room token for Flutter client.
    Allows streaming WebRTC audio directly to the LiveKit SFU without uploading large static .wav files.
    """
    target_room = room_name or f"room-{uuid.uuid4().hex[:8]}"
    participant_identity = identity or f"user-{uuid.uuid4().hex[:6]}"

    try:
        token = create_room_token(
            room_name=target_room,
            participant_identity=participant_identity,
            participant_name=name
        )
        return JoinTokenResponse(
            token=token,
            room_name=target_room,
            livekit_url=settings.LIVEKIT_URL,
            participant_identity=participant_identity
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate LiveKit join token: {str(e)}"
        )
