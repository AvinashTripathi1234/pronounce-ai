import 'package:flutter/material.dart';
import '../models/phoneme_feedback.dart';
import 'articulatory_sheet.dart';

class PhonemeHighlighterWidget extends StatelessWidget {
  final List<WordScore> words;
  final String fallbackSentence;

  const PhonemeHighlighterWidget({
    Key? key,
    required this.words,
    required this.fallbackSentence,
  }) : super(key: key);

  Color _getStatusColor(PhonemeStatus status) {
    switch (status) {
      case PhonemeStatus.correct:
        return const Color(0xFF10B981); // Emerald green (85%+)
      case PhonemeStatus.acceptable:
        return const Color(0xFFF59E0B); // Amber (65-84%)
      case PhonemeStatus.mispronounced:
        return const Color(0xFFEF4444); // Crimson red (<65%)
      case PhonemeStatus.pending:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      // Pending / Unspoken State
      final rawWords = fallbackSentence.split(' ');
      return Column(
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: rawWords.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap microphone below to record speech",
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      );
    }

    // Evaluated State with Interactive Clickable Phonemes
    return Column(
      children: [
        Wrap(
          spacing: 10.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: words.map((wordScore) {
            final isWordAccurate = wordScore.score >= 80;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isWordAccurate
                    ? const Color(0xFF10B981).withOpacity(0.10)
                    : const Color(0xFFEF4444).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isWordAccurate
                      ? const Color(0xFF10B981).withOpacity(0.35)
                      : const Color(0xFFEF4444).withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wordScore.word,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tappable Phoneme Chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: wordScore.phonemes.map((p) {
                      final color = _getStatusColor(p.status);
                      return GestureDetector(
                        onTap: () {
                          ArticulatorySheet.show(context, p, wordScore.word);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color, width: 1.2),
                          ),
                          child: Text(
                            "/${p.phoneme}/",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 14, color: Color(0xFF818CF8)),
            const SizedBox(width: 5),
            Text(
              "Tap any sound chip to inspect mouth & tongue placement",
              style: TextStyle(
                color: const Color(0xFF818CF8).withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
