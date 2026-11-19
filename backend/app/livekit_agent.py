import asyncio
import json
import logging
from typing import Optional

from livekit import rtc
from livekit.agents import (
    AutoSubscribe,
    JobContext,
    WorkerOptions,
    cli,
)

from app.config import get_settings
from app.services.audio_processor import AudioProcessor
from app.services.stt_alignment import PhonemeAlignmentService
from app.services.azure_speech import AzurePronunciationService
from app.services.scoring_engine import ScoringEngine
from app.services.supabase_service import SupabaseService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("livekit-pronunciation-agent")

settings = get_settings()
alignment_service = PhonemeAlignmentService(engine=settings.ALIGNMENT_ENGINE)
azure_service = AzurePronunciationService()
scoring_engine = ScoringEngine()
supabase_service = SupabaseService()

async def entrypoint(ctx: JobContext):
    """
    LiveKit Agent Entrypoint:
    Runs when a user joins an evaluation session room.
    Subscribes to audio tracks, reads raw PCM chunks with smart VAD,
    evaluates phonemes, and publishes real-time feedback over the LiveKit Data Channel.
    """
    logger.info(f"Connecting to room: {ctx.room.name}")
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)

    participant = await ctx.wait_for_participant()
    logger.info(f"Participant joined: {participant.identity}")

    target_sentence = "The quick brown fox jumps over the lazy dog"
    exercise_id = "ex-1"

    @ctx.room.on("data_received")
    def on_data_received(data_packet: rtc.DataPacket):
        """
        Receives control signals from Flutter client (e.g. exercise changes).
        """
        nonlocal target_sentence, exercise_id
        try:
            payload = json.loads(data_packet.data.decode("utf-8"))
            if payload.get("type") == "set_exercise":
                target_sentence = payload.get("sentence", target_sentence)
                exercise_id = payload.get("exercise_id", exercise_id)
                logger.info(f"Updated target exercise: '{target_sentence}' (ID: {exercise_id})")
        except Exception as e:
            logger.error(f"Error reading client data channel: {e}")

    @ctx.room.on("track_subscribed")
    def on_track_subscribed(
        track: rtc.Track,
        publication: rtc.TrackPublication,
        remote_participant: rtc.RemoteParticipant,
    ):
        if track.kind == rtc.TrackKind.KIND_AUDIO:
            logger.info(f"Subscribed to audio track from {remote_participant.identity}. Initializing VAD stream...")
            asyncio.create_task(
                process_audio_stream(
                    track,
                    ctx.room,
                    remote_participant.identity,
                    target_sentence,
                    exercise_id
                )
            )

async def process_audio_stream(
    track: rtc.AudioTrack,
    room: rtc.Room,
    participant_identity: str,
    target_sentence: str,
    exercise_id: str
):
    """
    Continuous audio processing loop:
    - Buffers raw 16-bit PCM frames
    - Performs Voice Activity Detection (VAD) via AudioProcessor
    - Evaluates complete utterances when speech pauses
    - Publishes low-latency feedback packets back to Flutter
    """
    audio_stream = rtc.AudioStream(track)
    pcm_buffer = bytearray()
    speech_active = False
    consecutive_silence_frames = 0

    async for event in audio_stream:
        frame = event.frame
        frame_bytes = frame.data

        # Resample from 48kHz (WebRTC default) to 16kHz if needed
        if frame.sample_rate == 48000:
            frame_bytes = AudioProcessor.resample_48k_to_16k(frame_bytes)

        # Check Voice Activity (VAD)
        is_voice = AudioProcessor.is_speech_active(frame_bytes, threshold_db=-42.0)

        if is_voice:
            speech_active = True
            consecutive_silence_frames = 0
            pcm_buffer.extend(frame_bytes)
        elif speech_active:
            # Utterance trailing buffer
            consecutive_silence_frames += 1
            pcm_buffer.extend(frame_bytes)

        # Trigger evaluation if:
        # 1. User spoke and has now paused for ~600ms (silence detected), OR
        # 2. Buffer reached ~3.5 seconds of active speech
        is_speech_ended = speech_active and consecutive_silence_frames >= 12
        is_buffer_full = len(pcm_buffer) >= (16000 * 2 * 3.5) # 3.5s of 16-bit 16kHz

        if (is_speech_ended or is_buffer_full) and len(pcm_buffer) >= (16000 * 2 * 0.8):
            logger.info(f"Evaluating utterance of {len(pcm_buffer)} bytes for '{target_sentence}'...")

            # 1. Phoneme & Prosody Assessment (Azure Speech or CTC / CMUDict)
            if settings.ALIGNMENT_ENGINE == "azure" or azure_service.is_configured:
                alignment = azure_service.assess_pcm_audio(
                    pcm_bytes=bytes(pcm_buffer),
                    reference_text=target_sentence,
                    sample_rate=16000
                )
            else:
                alignment = alignment_service.process_pcm_audio(
                    audio_bytes=bytes(pcm_buffer),
                    target_sentence=target_sentence,
                    sample_rate=16000
                )

            # 2. Feedback & Pedagogical Scoring (with LLM corrective physical tips)
            feedback = await scoring_engine.evaluate_async(alignment, reference_text=target_sentence)

            # 3. Publish real-time feedback back to Flutter via LiveKit Data Channel
            feedback_payload = json.dumps({
                "type": "phoneme_feedback",
                "is_final": True,
                "data": feedback
            }).encode("utf-8")

            await room.local_participant.publish_data(
                payload=feedback_payload,
                reliable=True
            )
            logger.info(f"Feedback published. Overall Score: {feedback.get('overall_score')}, Prosody: {feedback.get('prosody')}")

            # 4. Optional Supabase Persistence in background
            asyncio.create_task(
                supabase_service.record_practice_session(
                    user_id=participant_identity,
                    exercise_id=exercise_id,
                    room_name=room.name,
                    evaluation_result=feedback,
                    duration_seconds=round(len(pcm_buffer) / 32000.0, 2)
                )
            )

            # Reset VAD tracking for next utterance
            pcm_buffer.clear()
            speech_active = False
            consecutive_silence_frames = 0

if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
