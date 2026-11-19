import os
import json
import logging
import httpx
from typing import List, Dict, Any, Optional

logger = logging.getLogger("llm-feedback-service")

ARTICULATORY_FALLBACK_RULES: Dict[str, str] = {
    "θ": "Focus on the unvoiced /θ/ sound (in 'thought' or 'through')—place your tongue tip lightly between your front teeth and exhale gently without vibrating vocal cords.",
    "ð": "For the voiced /ð/ sound (in 'the' or 'weather')—place your tongue between your teeth and vibrate your vocal cords while releasing air.",
    "ɜːr": "For the rhotic /ɜːr/ (in 'perfect' or 'word')—curl the tip of your tongue slightly backward without letting it touch the roof of your mouth.",
    "æ": "For /æ/ (in 'practice' or 'cat')—drop your jaw open wider and flatten the tongue on the floor of your mouth.",
    "ʃ": "For /ʃ/ (in 'pronunciation')—round your lips slightly and channel air over the flat center of your tongue.",
    "dʒ": "For /dʒ/ (in 'jumps')—press tongue tip to the alveolar ridge behind your teeth, then burst out voiced friction."
}

class LLMFeedbackService:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY") or os.getenv("LLM_API_KEY", "")
        self.is_configured = bool(self.api_key)

    async def generate_corrective_tips(
        self,
        reference_text: str,
        transcription: str,
        phoneme_errors: List[Dict[str, Any]]
    ) -> List[str]:
        """
        Passes the transcription and phoneme error list into an LLM to generate
        surgical, actionable corrective tips for speech learners.
        """
        if not phoneme_errors:
            return ["Excellent articulation and natural flow! Keep up the consistent pronunciation."]

        # If LLM key is configured, query Gemini API for high-level speech coaching
        if self.is_configured:
            try:
                return await self._call_llm_api(reference_text, transcription, phoneme_errors)
            except Exception as e:
                logger.error(f"LLM API call failed, falling back to articulatory rules: {e}")

        # Fallback to expert articulatory rule engine
        return self._generate_rule_based_tips(phoneme_errors)

    async def _call_llm_api(
        self,
        reference_text: str,
        transcription: str,
        phoneme_errors: List[Dict[str, Any]]
    ) -> List[str]:
        """
        Queries Gemini API with a specialized pronunciation pedagogy prompt.
        """
        error_summary = [
            f"Phoneme /{e.get('phoneme')}/ in word '{e.get('word', '')}' (Acoustic Score: {e.get('score')}%)"
            for e in phoneme_errors[:3]
        ]
        
        prompt = f"""You are a world-class speech pathologist and accent coach.
Target sentence: "{reference_text}"
Spoken transcription: "{transcription}"
Detected phonetic errors:
{chr(10).join(error_summary)}

Provide exactly 1 or 2 concise, highly actionable physical instructions (focusing on tongue position, lips, jaw, or vocal cord vibration).
Output ONLY the bullet points, no preamble."""

        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.3, "maxOutputTokens": 200}
        }

        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.post(url, json=payload)
            if resp.status_code == 200:
                data = resp.json()
                raw_text = data["candidates"][0]["content"]["parts"][0]["text"].strip()
                lines = [line.lstrip("•-* ").strip() for line in raw_text.splitlines() if line.strip()]
                return lines[:2]
            else:
                logger.warning(f"Gemini API returned status {resp.status_code}")
                return self._generate_rule_based_tips(phoneme_errors)

    def _generate_rule_based_tips(self, phoneme_errors: List[Dict[str, Any]]) -> List[str]:
        """
        Generates expert physical articulation advice based on phonetic rules.
        """
        tips = []
        for err in phoneme_errors[:2]:
            p = err.get("phoneme", "")
            word = err.get("word", "")
            if p in ARTICULATORY_FALLBACK_RULES:
                tips.append(ARTICULATORY_FALLBACK_RULES[p])
            else:
                tips.append(f"In word '{word}', focus on crisp execution of the /{p}/ sound with steady airflow.")
        return tips
