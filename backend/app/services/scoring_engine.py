from typing import Dict, Any, List
from app.services.llm_feedback import LLMFeedbackService

class ScoringEngine:
    def __init__(self):
        self.llm_feedback = LLMFeedbackService()

    async def evaluate_async(self, alignment_data: Dict[str, Any], reference_text: str = "") -> Dict[str, Any]:
        """
        Evaluates pronunciation and generates LLM-powered corrective physical tips.
        """
        result = self.evaluate(alignment_data)
        
        # Extract phoneme errors for LLM prompt
        phoneme_errors = []
        for w in result.get("words", []):
            for p in w.get("phonemes", []):
                if p.get("status") in ["mispronounced", "acceptable"]:
                    phoneme_errors.append({
                        "word": w.get("word"),
                        "phoneme": p.get("phoneme"),
                        "score": p.get("score")
                    })

        if phoneme_errors:
            llm_tips = await self.llm_feedback.generate_corrective_tips(
                reference_text=reference_text or alignment_data.get("transcript", ""),
                transcription=alignment_data.get("transcript", reference_text),
                phoneme_errors=phoneme_errors
            )
            if llm_tips:
                result["tips"] = llm_tips

        return result

    def evaluate(self, alignment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calculates holistic pronunciation score, identifies specific weak points,
        and generates actionable pronunciation coaching tips.
        """
        words = alignment_data.get("words", [])
        if not words:
            return {
                "overall_score": 0.0,
                "accuracy": 0.0,
                "fluency": 0.0,
                "completeness": 0.0,
                "words": [],
                "tips": ["No audio speech detected. Please speak clearly into the microphone."]
            }

        all_phoneme_scores = []
        weak_phonemes = []

        for w in words:
            for p in w["phonemes"]:
                score = p["score"]
                all_phoneme_scores.append(score)
                if p["status"] in ["mispronounced", "acceptable"]:
                    weak_phonemes.append(p["phoneme"])

        # Core metric calculations (aligned with Azure Speech & Prosody Spec)
        accuracy = alignment_data.get("accuracy_score") or (sum(all_phoneme_scores) / max(1, len(all_phoneme_scores)))
        duration = alignment_data.get("duration", 2.0)
        expected_duration = max(1.0, len(words) * 0.45)
        
        # Fluency calculation based on speaking rate & consistency
        speed_ratio = duration / expected_duration
        if "fluency_score" in alignment_data:
            fluency = alignment_data["fluency_score"]
        elif 0.7 <= speed_ratio <= 1.4:
            fluency = min(100.0, accuracy * 0.95 + 5.0)
        else:
            fluency = max(50.0, accuracy - 15.0)

        # Prosody score (pitch, rhythm, intonation variation)
        prosody = alignment_data.get("prosody_score", round(fluency * 0.94, 1))

        completeness = alignment_data.get("completeness_score", 100.0 if len(words) > 0 else 0.0)

        # Overall weighted score incorporating prosody
        overall = (accuracy * 0.40) + (fluency * 0.25) + (prosody * 0.25) + (completeness * 0.10)

        # Generate targeted tips
        tips: List[str] = []
        unique_weak = list(dict.fromkeys(weak_phonemes))
        for p in unique_weak[:2]:
            if p in PHONEME_TIPS:
                tips.append(f"Phoneme /{p}/: {PHONEME_TIPS[p]}")

        if prosody < 75:
            tips.append("Intonation tip: Emphasize key content words and gently rise/fall at phrase boundaries.")

        if not tips and overall >= 90:
            tips.append("Outstanding clarity, rhythm, and natural prosody! Your accent is spot-on.")
        elif not tips:
            tips.append("Good rhythm. Pay close attention to vowel length and consonant endings.")

        return {
            "overall_score": round(overall, 1),
            "accuracy": round(accuracy, 1),
            "fluency": round(fluency, 1),
            "prosody": round(prosody, 1),
            "completeness": round(completeness, 1),
            "words": words,
            "tips": tips
        }
