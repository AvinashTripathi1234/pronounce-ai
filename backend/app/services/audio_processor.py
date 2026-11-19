import math
import struct
import io
import wave
from typing import Tuple, List

class AudioProcessor:
    """
    High-performance audio processing utility for WebRTC audio streams:
    - Downsampling from WebRTC 48kHz to 16kHz mono (standard for ASR & phonetic models)
    - RMS Energy & Decibel calculation
    - Voice Activity Detection (VAD) with silence threshold tracking
    - WAV packaging for alignment and external speech APIs
    """

    @staticmethod
    def calculate_rms(pcm_bytes: bytes) -> float:
        """
        Calculates Root Mean Square (RMS) amplitude of 16-bit signed PCM audio.
        """
        if not pcm_bytes or len(pcm_bytes) < 2:
            return 0.0

        sample_count = len(pcm_bytes) // 2
        # Unpack as little-endian signed 16-bit integers ('<h')
        format_str = f"<{sample_count}h"
        try:
            samples = struct.unpack(format_str, pcm_bytes[:sample_count * 2])
            sum_squares = sum(s * s for s in samples)
            mean_square = sum_squares / max(1, sample_count)
            return math.sqrt(mean_square)
        except Exception:
            return 0.0

    @staticmethod
    def calculate_db(rms: float) -> float:
        """
        Converts RMS amplitude to approximate dBFS (Decibels relative to Full Scale).
        Max 16-bit integer is 32767.
        """
        if rms <= 0:
            return -96.0
        return 20 * math.log10(rms / 32767.0)

    @staticmethod
    def is_speech_active(pcm_bytes: bytes, threshold_db: float = -42.0) -> bool:
        """
        Determines whether the audio chunk contains voice activity above ambient silence.
        """
        rms = AudioProcessor.calculate_rms(pcm_bytes)
        db = AudioProcessor.calculate_db(rms)
        return db > threshold_db

    @staticmethod
    def resample_48k_to_16k(pcm_bytes: bytes) -> bytes:
        """
        Downsamples 48kHz 16-bit signed mono PCM to 16kHz (3:1 decimation).
        Standard for speech-to-text models like Whisper and Azure Speech.
        """
        if not pcm_bytes or len(pcm_bytes) < 6:
            return pcm_bytes

        sample_count = len(pcm_bytes) // 2
        samples = struct.unpack(f"<{sample_count}h", pcm_bytes[:sample_count * 2])
        
        # 3:1 decimation with simple 3-tap averaging filter to prevent aliasing
        downsampled = []
        for i in range(0, sample_count - 2, 3):
            avg = (samples[i] + samples[i + 1] + samples[i + 2]) // 3
            downsampled.append(avg)

        return struct.pack(f"<{len(downsampled)}h", *downsampled)

    @staticmethod
    def pcm_to_wav_bytes(pcm_bytes: bytes, sample_rate: int = 16000, channels: int = 1) -> bytes:
        """
        Wraps raw PCM bytes in a standard RIFF/WAVE header container.
        """
        buf = io.BytesIO()
        with wave.open(buf, 'wb') as wav_file:
            wav_file.setnchannels(channels)
            wav_file.setsampwidth(2) # 16-bit
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(pcm_bytes)
        return buf.getvalue()
