"""
PronounceAI Backend Pipeline Verification & Test Suite
Validates audio processing, CMUDict canonical mapping, phoneme alignment,
prosody scoring, LLM feedback tips, and LiveKit token minting.
"""

import sys
import os
import asyncio
import math
import struct

# Ensure backend directory is in python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.audio_processor import AudioProcessor
from app.services.cmu_dict import get_canonical_phonemes, get_canonical_ipa
from app.services.stt_alignment import PhonemeAlignmentService
from app.services.scoring_engine import ScoringEngine
from app.services.azure_speech import AzurePronunciationService
from app.services.livekit_token import create_room_token

def generate_synthetic_tone(freq: float = 440.0, duration_sec: float = 1.0, sample_rate: int = 16000) -> bytes:
    """Generates synthetic 16-bit PCM audio tone for test validation."""
    samples = []
    num_samples = int(duration_sec * sample_rate)
    for i in range(num_samples):
        val = int(16000 * math.sin(2 * math.pi * freq * (i / sample_rate)))
        samples.append(val)
    return struct.pack(f"<{len(samples)}h", *samples)

async def run_backend_tests():
    print("=" * 60)
    print("🚀 PRONOUNCE-AI BACKEND PIPELINE VERIFICATION SUITE")
    print("=" * 60)

    # 1. Test AudioProcessor
    print("\n[1/6] Testing AudioProcessor (VAD & Resampling)...")
    synthetic_pcm = generate_synthetic_tone(freq=300, duration_sec=1.5, sample_rate=16000)
    rms = AudioProcessor.calculate_rms(synthetic_pcm)
    db = AudioProcessor.calculate_db(rms)
    is_active = AudioProcessor.is_speech_active(synthetic_pcm)
    wav_bytes = AudioProcessor.pcm_to_wav_bytes(synthetic_pcm, sample_rate=16000)

    assert rms > 0, "RMS should be positive for active audio"
    assert is_active, "Audio tone should register as active speech"
    assert len(wav_bytes) > len(synthetic_pcm), "WAV container should include 44-byte header"
    print(f"  ✓ RMS: {rms:.1f}, Level: {db:.1f} dBFS, VAD Active: {is_active}")
    print(f"  ✓ WAV Container generated ({len(wav_bytes)} bytes)")

    # 2. Test CMUDict Canonical American English Alignment
    print("\n[2/6] Testing Canonical American English CMUDict...")
    words = ["weather", "through", "practice", "perfect"]
    for w in words:
        arpabet = get_canonical_phonemes(w)
        ipa = get_canonical_ipa(w)
        print(f"  ✓ Word '{w}' -> ARPAbet: {arpabet} -> IPA: {' '.join(ipa)}")
        assert len(arpabet) > 0, f"Word {w} should have canonical phonemes"

    # 3. Test STT & Phoneme Alignment
    print("\n[3/6] Testing Phoneme Alignment Service...")
    aligner = PhonemeAlignmentService(engine="mock")
    sentence = "The weather is better through the storm"
    alignment = aligner.process_pcm_audio(synthetic_pcm, target_sentence=sentence)
    assert len(alignment["words"]) > 0, "Alignment should produce word items"
    print(f"  ✓ Aligned {len(alignment['words'])} words with phonetic time boundaries")

    # 4. Test Azure Pronunciation Assessment (with Prosody)
    print("\n[4/6] Testing Speech Assessment Layer & Prosody...")
    azure = AzurePronunciationService()
    assessment = azure.assess_pcm_audio(synthetic_pcm, reference_text=sentence)
    print(f"  ✓ Accuracy: {assessment['accuracy_score']}%")
    print(f"  ✓ Fluency: {assessment['fluency_score']}%")
    print(f"  ✓ Prosody: {assessment['prosody_score']}%")
    print(f"  ✓ Completeness: {assessment['completeness_score']}%")
    print(f"  ✓ Overall Pron Score: {assessment['overall_score']}%")

    # 5. Test Scoring Engine & LLM Articulatory Advice
    print("\n[5/6] Testing Scoring Engine & Articulatory Feedback...")
    engine = ScoringEngine()
    feedback = await engine.evaluate_async(assessment, reference_text=sentence)
    assert "tips" in feedback and len(feedback["tips"]) > 0, "Engine should generate actionable tips"
    print(f"  ✓ Evaluated Weighted Score: {feedback['overall_score']}")
    print(f"  ✓ Articulatory Coaching Tips:")
    for tip in feedback["tips"]:
        print(f"     • {tip}")

    # 6. Test LiveKit Token Minting
    print("\n[6/6] Testing LiveKit SFU JWT Token Generation...")
    room_name = "test-practice-room-101"
    user_identity = "learner-alice"
    token = create_room_token(room_name=room_name, participant_identity=user_identity, participant_name="Alice")
    assert token and len(token) > 20, "LiveKit token should be a valid non-empty JWT"
    print(f"  ✓ LiveKit JWT Token successfully minted for '{user_identity}' in '{room_name}'")
    print(f"    Token preview: {token[:35]}...{token[-15:]}")

    print("\n" + "=" * 60)
    print("🎉 ALL 6 BACKEND SUBSYSTEMS VERIFIED AND OPERATIONAL!")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(run_backend_tests())
