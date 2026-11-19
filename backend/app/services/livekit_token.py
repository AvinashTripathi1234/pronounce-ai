from livekit import api
from app.config import get_settings

def create_room_token(room_name: str, participant_identity: str, participant_name: str = "") -> str:
    """
    Generates a secure LiveKit Access Token allowing the client to:
    - Join the designated room
    - Publish microphone audio track
    - Subscribe to tracks and data channels
    """
    settings = get_settings()

    grant = api.VideoGrants(
        room_join=True,
        room=room_name,
        can_publish=True,
        can_subscribe=True,
        can_publish_data=True
    )

    token = (
        api.AccessToken(settings.LIVEKIT_API_KEY, settings.LIVEKIT_API_SECRET)
        .with_identity(participant_identity)
        .with_name(participant_name or participant_identity)
        .with_grants(grant)
    )

    return token.to_jwt()
