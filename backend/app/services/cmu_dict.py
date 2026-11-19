"""
CMUDict (Carnegie Mellon University Pronouncing Dictionary)
Canonical American English Phonetic Reference & ARPAbet-to-IPA Mappings
"""

from typing import Dict, List, Optional

# ARPAbet to International Phonetic Alphabet (IPA) conversion table
ARPABET_TO_IPA: Dict[str, str] = {
    # Vowels
    "AA": "ɑ",
    "AE": "æ",
    "AH": "ʌ",
    "AO": "ɔ",
    "AW": "aʊ",
    "AY": "aɪ",
    "EH": "ɛ",
    "ER": "ɜːr",
    "EY": "eɪ",
    "IH": "ɪ",
    "IY": "i",
    "OW": "oʊ",
    "OY": "ɔɪ",
    "UH": "ʊ",
    "UW": "u",
    # Consonants
    "B": "b",
    "CH": "tʃ",
    "D": "d",
    "DH": "ð",
    "F": "f",
    "G": "ɡ",
    "HH": "h",
    "JH": "dʒ",
    "K": "k",
    "L": "l",
    "M": "m",
    "N": "n",
    "NG": "ŋ",
    "P": "p",
    "R": "r",
    "S": "s",
    "SH": "ʃ",
    "T": "t",
    "TH": "θ",
    "V": "v",
    "W": "w",
    "Y": "j",
    "Z": "z",
    "ZH": "ʒ",
}

# Canonical CMUDict transcriptions for common vocabulary & exercise sentences
CANONICAL_CMUDICT: Dict[str, List[str]] = {
    "the": ["DH", "AH0"],
    "weather": ["W", "EH1", "DH", "ER0"],
    "is": ["IH1", "Z"],
    "better": ["B", "EH1", "T", "ER0"],
    "through": ["TH", "R", "UW1"],
    "storm": ["S", "T", "AO1", "R", "M"],
    "practice": ["P", "R", "AE1", "K", "T", "AH0", "S"],
    "makes": ["M", "EY1", "K", "S"],
    "perfect": ["P", "ER0", "F", "EH1", "K", "T"],
    "pronunciation": ["P", "R", "OW0", "N", "AH2", "N", "S", "IY0", "EY1", "SH", "AH0", "N"],
    "quick": ["K", "W", "IH1", "K"],
    "brown": ["B", "R", "AW1", "N"],
    "fox": ["F", "AA1", "K", "S"],
    "jumps": ["JH", "AH1", "M", "P", "S"],
    "over": ["OW1", "V", "ER0"],
    "lazy": ["L", "EY1", "Z", "IY0"],
    "dog": ["D", "AO1", "G"],
    "thought": ["TH", "AO1", "T"],
    "feather": ["F", "EH1", "DH", "ER0"],
}

def get_canonical_phonemes(word: str) -> List[str]:
    """
    Returns canonical ARPAbet phonemes stripped of stress digits for acoustic comparison.
    """
    cleaned = word.strip().lower().replace(",", "").replace(".", "").replace("!", "").replace("?", "")
    raw = CANONICAL_CMUDICT.get(cleaned, [])
    # Strip stress numbers (e.g. 'AH0' -> 'AH')
    return [p.rstrip("012") for p in raw]

def get_canonical_ipa(word: str) -> List[str]:
    """
    Returns IPA phoneme symbols from canonical American English CMUDict.
    """
    arpabet_list = get_canonical_phonemes(word)
    return [ARPABET_TO_IPA.get(p, p.lower()) for p in arpabet_list]
