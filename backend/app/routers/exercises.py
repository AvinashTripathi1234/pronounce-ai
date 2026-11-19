from fastapi import APIRouter
from typing import List
from pydantic import BaseModel

router = APIRouter(prefix="/exercises", tags=["Exercises"])

class Exercise(BaseModel):
    id: str
    title: str
    sentence: str
    ipa_display: str
    difficulty: str
    target_phonemes: List[str]
    hint: str

SAMPLE_EXERCISES: List[Exercise] = [
    Exercise(
        id="ex-1",
        title="Voiced & Voiceless 'TH'",
        sentence="The weather is better through the storm",
        ipa_display="ðə ˈwɛðər ɪz ˈbɛtər θruː ðə stɔːrm",
        difficulty="Intermediate",
        target_phonemes=["ð", "θ", "ɛ"],
        hint="Contrast the voiced /ð/ in 'the' with the unvoiced /θ/ in 'through'."
    ),
    Exercise(
        id="ex-2",
        title="Rhotic R & Liquids",
        sentence="Practice makes perfect pronunciation",
        ipa_display="ˈpræktɪs meɪks ˈpɜːrfɪkt prəˌnʌnsiˈeɪʃən",
        difficulty="Advanced",
        target_phonemes=["ɜːr", "æ", "ʃ"],
        hint="Curl the tongue back for /ɜːr/ in 'perfect' without touching the palate."
    ),
    Exercise(
        id="ex-3",
        title="Pacing and Articulation",
        sentence="The quick brown fox jumps over the lazy dog",
        ipa_display="ðə kwɪk braʊn fɒks dʒʌmps ˈoʊvər ðə ˈleɪzi dɔːɡ",
        difficulty="Beginner",
        target_phonemes=["kw", "dʒ", "z"],
        hint="Keep words connected smoothly while hitting crisp consonants."
    ),
    Exercise(
        id="ex-4",
        title="Short Vowel Distinction /æ/ vs /ɛ/",
        sentence="The cat sat on the red bed",
        ipa_display="ðə kæt sæt ɒn ðə rɛd bɛd",
        difficulty="Beginner",
        target_phonemes=["æ", "ɛ"],
        hint="Drop your jaw lower for /æ/ in 'cat' compared to /ɛ/ in 'bed'."
    ),
    Exercise(
        id="ex-5",
        title="Postalveolar & Sibilants",
        sentence="She sells sea shells by the sunny seashore",
        ipa_display="ʃiː sɛlz siː ʃɛlz baɪ ðə ˈsʌni ˈsiːʃɔːr",
        difficulty="Advanced",
        target_phonemes=["ʃ", "s", "z"],
        hint="Switch cleanly between the /s/ alveolar hiss and /ʃ/ postalveolar flare."
    )
]

@router.get("", response_model=List[Exercise])
def get_exercises():
    return SAMPLE_EXERCISES

@router.get("/{exercise_id}", response_model=Exercise)
def get_exercise_by_id(exercise_id: str):
    for ex in SAMPLE_EXERCISES:
        if ex.id == exercise_id:
            return ex
    return SAMPLE_EXERCISES[0]
