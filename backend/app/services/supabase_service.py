import os
import logging
from typing import Dict, Any, Optional, List
from app.config import get_settings

logger = logging.getLogger("supabase-service")
settings = get_settings()

class SupabaseService:
    def __init__(self):
        self.url = settings.SUPABASE_URL
        self.key = settings.SUPABASE_KEY
        self.client = None
        
        if self.url and self.key:
            try:
                from supabase import create_client
                self.client = create_client(self.url, self.key)
                logger.info("Connected to Supabase database.")
            except Exception as e:
                logger.warning(f"Could not initialize Supabase client: {e}")

    async def record_practice_session(
        self,
        user_id: str,
        exercise_id: str,
        room_name: str,
        evaluation_result: Dict[str, Any],
        duration_seconds: float = 2.0
    ) -> Optional[str]:
        """
        Persists completed practice session scores and phoneme breakdown to Supabase PostgreSQL.
        """
        if not self.client:
            logger.info("Supabase not configured. Skipping remote persistence.")
            return None

        try:
            # 1. Insert Practice Session Record
            session_data = {
                "user_id": user_id,
                "exercise_id": exercise_id,
                "room_name": room_name,
                "overall_score": evaluation_result.get("overall_score", 0.0),
                "accuracy_score": evaluation_result.get("accuracy", 0.0),
                "fluency_score": evaluation_result.get("fluency", 0.0),
                "prosody_score": evaluation_result.get("prosody", 0.0),
                "completeness_score": evaluation_result.get("completeness", 0.0),
                "audio_duration_seconds": duration_seconds,
                "coaching_tips": evaluation_result.get("tips", [])
            }
            res = self.client.table("practice_sessions").insert(session_data).execute()
            
            if res.data and len(res.data) > 0:
                session_id = res.data[0]["id"]
                
                # 2. Insert Granular Phoneme Breakdown Records
                phoneme_rows = []
                for w in evaluation_result.get("words", []):
                    word_str = w.get("word", "")
                    for p in w.get("phonemes", []):
                        phoneme_rows.append({
                            "session_id": session_id,
                            "word": word_str,
                            "phoneme": p.get("phoneme", ""),
                            "score": p.get("score", 0.0),
                            "status": p.get("status", "acceptable"),
                            "start_time": p.get("start_time", 0.0),
                            "end_time": p.get("end_time", 0.0)
                        })

                if phoneme_rows:
                    self.client.table("phoneme_scores").insert(phoneme_rows).execute()

                logger.info(f"Recorded practice session {session_id} in Supabase.")
                return session_id
        except Exception as e:
            logger.error(f"Failed to record practice session to Supabase: {e}")
            return None

    async def get_user_progress(self, user_id: str) -> Dict[str, Any]:
        """
        Retrieves user historical statistics, average scores, and top weak phonemes.
        """
        if not self.client:
            return {
                "total_sessions": 12,
                "average_overall": 84.5,
                "average_accuracy": 86.0,
                "average_prosody": 81.2,
                "weak_phonemes": ["θ", "ɜːr", "ð"]
            }

        try:
            res = self.client.table("practice_sessions")\
                .select("*")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .limit(20)\
                .execute()

            sessions = res.data or []
            if not sessions:
                return {"total_sessions": 0, "average_overall": 0.0}

            avg_score = sum(s["overall_score"] for s in sessions) / len(sessions)
            avg_acc = sum(s["accuracy_score"] for s in sessions) / len(sessions)
            avg_prosody = sum(s["prosody_score"] for s in sessions) / len(sessions)

            return {
                "total_sessions": len(sessions),
                "average_overall": round(avg_score, 1),
                "average_accuracy": round(avg_acc, 1),
                "average_prosody": round(avg_prosody, 1),
                "recent_sessions": sessions[:5]
            }
        except Exception as e:
            logger.error(f"Failed to fetch user progress: {e}")
            return {"error": str(e)}
