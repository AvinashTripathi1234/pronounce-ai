enum PhonemeStatus {
  correct,
  acceptable,
  mispronounced,
  pending;

  static PhonemeStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'correct':
        return PhonemeStatus.correct;
      case 'acceptable':
        return PhonemeStatus.acceptable;
      case 'mispronounced':
        return PhonemeStatus.mispronounced;
      default:
        return PhonemeStatus.pending;
    }
  }
}

class PhonemeScore {
  final String phoneme;
  final double score;
  final PhonemeStatus status;
  final double startTime;
  final double endTime;

  PhonemeScore({
    required this.phoneme,
    required this.score,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory PhonemeScore.fromJson(Map<String, dynamic> json) {
    return PhonemeScore(
      phoneme: json['phoneme'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: PhonemeStatus.fromString(json['status'] as String? ?? 'pending'),
      startTime: (json['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['end_time'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WordScore {
  final String word;
  final double score;
  final List<PhonemeScore> phonemes;

  WordScore({
    required this.word,
    required this.score,
    required this.phonemes,
  });

  factory WordScore.fromJson(Map<String, dynamic> json) {
    return WordScore(
      word: json['word'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      phonemes: (json['phonemes'] as List<dynamic>?)
              ?.map((e) => PhonemeScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PronunciationFeedback {
  final double overallScore;
  final double accuracy;
  final double fluency;
  final double prosody;
  final double completeness;
  final List<WordScore> words;
  final List<String> tips;
  final bool isFinal;

  PronunciationFeedback({
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.prosody,
    required this.completeness,
    required this.words,
    required this.tips,
    this.isFinal = false,
  });

  factory PronunciationFeedback.empty() {
    return PronunciationFeedback(
      overallScore: 0.0,
      accuracy: 0.0,
      fluency: 0.0,
      prosody: 0.0,
      completeness: 0.0,
      words: [],
      tips: [],
      isFinal: false,
    );
  }

  factory PronunciationFeedback.fromJson(Map<String, dynamic> json, {bool isFinal = false}) {
    return PronunciationFeedback(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? (json['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      fluency: (json['fluency'] as num?)?.toDouble() ?? (json['fluency_score'] as num?)?.toDouble() ?? 0.0,
      prosody: (json['prosody'] as num?)?.toDouble() ?? (json['prosody_score'] as num?)?.toDouble() ?? 0.0,
      completeness: (json['completeness'] as num?)?.toDouble() ?? (json['completeness_score'] as num?)?.toDouble() ?? 0.0,
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFinal: isFinal,
    );
  }
}
