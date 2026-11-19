import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.services.audio_processor import AudioProcessor
from app.services.stt_alignment import PhonemeAlignmentService
from app.services.scoring_engine import ScoringEngine
from app.services.azure_speech import AzurePronunciationService
from app.config import get_settings

router = APIRouter(prefix="/v1/stream", tags=["Direct WebSocket Streaming"])
logger = logging.getLogger("websocket-audio-streaming")

settings = get_settings()
alignment_service = PhonemeAlignmentService(engine=settings.ALIGNMENT_ENGINE)
scoring_engine = ScoringEngine()
azure_service = AzurePronunciationService()

@router.websocket("/ws")
async def websocket_audio_stream(
    websocket: WebSocket,
    sentence: str = Query(default="The quick brown fox jumps over the lazy dog"),
    sample_rate: int = Query(default=16000)
):
    """
    Direct Real-Time WebSocket Streaming Endpoint:
    Allows clients or testing harnesses to stream raw binary PCM audio frames directly.
    Runs VAD, accumulates speech, and returns real-time phoneme evaluation JSON packets.
    """
    await websocket.accept()
    logger.info(f"WebSocket audio client connected for sentence: '{sentence}'")

    audio_buffer = bytearray()
    silence_chunks = 0
    speech_detected = False

    try:
        while True:
            # Receive binary PCM chunk or text control message
            message = await websocket.receive()
            
            if "bytes" in message and message["bytes"]:
                chunk = message["bytes"]
                
                # Check Voice Activity (VAD)
                is_active = AudioProcessor.is_speech_active(chunk, threshold_db=-40.0)
                
                if is_active:
                    speech_detected = True
                    silence_chunks = 0
                    audio_buffer.extend(chunk)
                elif speech_detected:
                    silence_chunks += 1
                    audio_buffer.extend(chunk)

                # If speech has been detected and is followed by silence (end of utterance)
                # or buffer exceeds 2 seconds of audio
                should_evaluate = (
                    (speech_detected and silence_chunks >= 4 and len(audio_buffer) >= sample_rate * 2) or
                    (len(audio_buffer) >= sample_rate * 2 * 3) # Max 3 second window
                )

                if should_evaluate:
                    logger.info("Speech pause detected. Running phoneme alignment & prosody evaluation...")
                    
                    if settings.ALIGNMENT_ENGINE == "azure" or azure_service.is_configured:
                        alignment = azure_service.assess_pcm_audio(
                            pcm_bytes=bytes(audio_buffer),
                            reference_text=sentence,
                            sample_rate=sample_rate
                        )
                    else:
                        alignment = alignment_service.process_pcm_audio(
                            audio_bytes=bytes(audio_buffer),
                            target_sentence=sentence,
                            sample_rate=sample_rate
                        )

                    feedback = await scoring_engine.evaluate_async(alignment, reference_text=sentence)

                    # Send evaluation back to WebSocket client
                    await websocket.send_text(json.dumps({
                        "type": "phoneme_feedback",
                        "is_final": True,
                        "data": feedback
                    }))

                    # Reset buffer for next utterance
                    audio_buffer.clear()
                    speech_detected = False
                    silence_chunks = 0

            elif "text" in message:
                try:
                    cmd = json.loads(message["text"])
                    if cmd.get("type") == "set_sentence":
                        sentence = cmd.get("sentence", sentence)
                        logger.info(f"Updated WebSocket target sentence: '{sentence}'")
                        await websocket.send_text(json.dumps({
                            "type": "sentence_updated",
                            "sentence": sentence
                        }))
                except Exception as e:
                    logger.error(f"Error parsing WebSocket text command: {e}")

    except WebSocketDisconnect:
        logger.info("WebSocket audio client disconnected.")
    except Exception as e:
        logger.error(f"WebSocket streaming error: {e}")
