class Exercise {
  final String id;
  final String title;
  final String sentence;
  final String ipaDisplay;
  final String difficulty;
  final List<String> targetPhonemes;
  final String hint;

  Exercise({
    required this.id,
    required this.title,
    required this.sentence,
    required this.ipaDisplay,
    required this.difficulty,
    required this.targetPhonemes,
    required this.hint,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? 'ex-1',
      title: json['title'] as String? ?? 'Exercise',
      sentence: json['sentence'] as String? ?? '',
      ipaDisplay: json['ipa_display'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      targetPhonemes: (json['target_phonemes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hint: json['hint'] as String? ?? '',
    );
  }

  static List<Exercise> defaultExercises = [
    Exercise(
      id: 'ex-1',
      title: "Voiced & Voiceless 'TH'",
      sentence: "The weather is better through the storm",
      ipaDisplay: "ðə ˈwɛðər ɪz ˈbɛtər θruː ðə stɔːrm",
      difficulty: "Intermediate",
      targetPhonemes: ["ð", "θ", "ɛ"],
      hint: "Contrast the voiced /ð/ in 'the' with the unvoiced /θ/ in 'through'.",
    ),
    Exercise(
      id: 'ex-2',
      title: "Rhotic R & Liquids",
      sentence: "Practice makes perfect pronunciation",
      ipaDisplay: "ˈpræktɪs meɪks ˈpɜːrfɪkt prəˌnʌnsiˈeɪʃən",
      difficulty: "Advanced",
      targetPhonemes: ["ɜːr", "æ", "ʃ"],
      hint: "Curl the tongue back for /ɜːr/ in 'perfect' without touching the palate.",
    ),
    Exercise(
      id: 'ex-3',
      title: "Pacing & Articulation",
      sentence: "The quick brown fox jumps over the lazy dog",
      ipaDisplay: "ðə kwɪk braʊn fɒks dʒʌmps ˈoʊvər ðə ˈleɪzi dɔːɡ",
      difficulty: "Beginner",
      targetPhonemes: ["kw", "dʒ", "z"],
      hint: "Keep words connected smoothly while hitting crisp consonants.",
    ),
    Exercise(
      id: 'ex-4',
      title: "Short Vowels /æ/ vs /ɛ/",
      sentence: "The cat sat on the red bed",
      ipaDisplay: "ðə kæt sæt ɒn ðə rɛd bɛd",
      difficulty: "Beginner",
      targetPhonemes: ["æ", "ɛ"],
      hint: "Drop your jaw lower for /æ/ in 'cat' compared to /ɛ/ in 'bed'.",
    ),
    Exercise(
      id: 'ex-5',
      title: "Postalveolar & Sibilants",
      sentence: "She sells sea shells by the sunny seashore",
      ipaDisplay: "ʃiː sɛlz siː ʃɛlz baɪ ðə ˈsʌni ˈsiːʃɔːr",
      difficulty: "Advanced",
      targetPhonemes: ["ʃ", "s", "z"],
      hint: "Switch cleanly between the /s/ alveolar hiss and /ʃ/ postalveolar flare.",
    ),
  ];
}
