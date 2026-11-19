import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/phoneme_feedback.dart';
import '../core/tts_service.dart';

class ArticulatorySheet extends StatelessWidget {
  final PhonemeScore phonemeScore;
  final String word;

  const ArticulatorySheet({
    Key? key,
    required this.phonemeScore,
    required this.word,
  }) : super(key: key);

  static void show(BuildContext context, PhonemeScore phonemeScore, String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ArticulatorySheet(phonemeScore: phonemeScore, word: word),
    );
  }

  Map<String, dynamic> _getArticulationData(String phoneme) {
    switch (phoneme) {
      case 'θ':
        return {
          'name': 'Voiceless Dental Fricative',
          'tonguePos': 'interdental',
          'voiced': false,
          'instructions': [
            'Place the tip of your tongue lightly between your upper and lower teeth.',
            'Do NOT bite down—allow air to push smoothly through the gap.',
            'Keep your vocal cords silent (no buzzing vibration).'
          ],
          'examples': ['thought', 'through', 'thin', 'math'],
          'commonMistake': 'Often substituted with /s/ or /t/.'
        };
      case 'ð':
        return {
          'name': 'Voiced Dental Fricative',
          'tonguePos': 'interdental',
          'voiced': true,
          'instructions': [
            'Position your tongue between your teeth exactly like /θ/.',
            'Vibrate your vocal cords to add voice (feel the buzz in your throat).',
            'Keep continuous airflow without fully blocking it like a /d/.'
          ],
          'examples': ['the', 'this', 'weather', 'breathe'],
          'commonMistake': 'Often substituted with /d/ or /z/.'
        };
      case 'ɜːr':
      case 'r':
        return {
          'name': 'Rhotic Approximant / Nurse Vowel',
          'tonguePos': 'retroflex',
          'voiced': true,
          'instructions': [
            'Curl the tip of your tongue up and slightly backward (retroflex).',
            'Do NOT let the tongue touch the roof of your mouth.',
            'Tense the sides of the tongue against the upper back molars.'
          ],
          'examples': ['perfect', 'world', 'learn', 'bird'],
          'commonMistake': 'Often pronounced flat without rhotic coloring.'
        };
      case 'æ':
        return {
          'name': 'Near-Open Front Unrounded Vowel',
          'tonguePos': 'open_front',
          'voiced': true,
          'instructions': [
            'Drop your jaw significantly lower than for /e/ (as in bed).',
            'Keep the body of the tongue flat on the floor of the mouth.',
            'Spread the lips slightly in a relaxed smile.'
          ],
          'examples': ['practice', 'cat', 'apple', 'fast'],
          'commonMistake': 'Often confused with /ɛ/ (bed) or /ʌ/ (cup).'
        };
      case 'ʃ':
        return {
          'name': 'Voiceless Postalveolar Fricative',
          'tonguePos': 'postalveolar',
          'voiced': false,
          'instructions': [
            'Raise the blade of your tongue close to the ridge behind front teeth.',
            'Round and flare your lips forward into a soft trumpet shape.',
            'Channel a steady hiss of air over the center of your tongue.'
          ],
          'examples': ['pronunciation', 'ship', 'nation', 'wash'],
          'commonMistake': 'Tongue placed too far forward, sounding like /s/.'
        };
      default:
        return {
          'name': 'Standard Phoneme',
          'tonguePos': 'alveolar',
          'voiced': true,
          'instructions': [
            'Align tongue shape with the target IPA consonant/vowel.',
            'Maintain steady breath control and clear acoustic release.'
          ],
          'examples': [word],
          'commonMistake': 'Pacing or vowel length variation.'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = phonemeScore.phoneme;
    final info = _getArticulationData(p);
    final score = phonemeScore.score;
    final isVoiced = info['voiced'] as bool;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.5),
          left: BorderSide(color: Color(0xFF334155), width: 1.5),
          right: BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header: Phoneme & Word
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                    ),
                    child: Text(
                      "/$p/",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "In word: \"$word\"",
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              // Accuracy Score Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: score >= 80
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : (score >= 65
                          ? const Color(0xFFF59E0B).withOpacity(0.2)
                          : const Color(0xFFEF4444).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: score >= 80
                        ? const Color(0xFF10B981)
                        : (score >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                  ),
                ),
                child: Text(
                  "${score.toInt()}% Match",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: score >= 80
                        ? const Color(0xFF10B981)
                        : (score >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Replay Sound Button (Native Pronunciation Drill)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    TtsService().speakWord(word);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: Text("Hear \"$word\" in Isolation"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2D Sagittal Vocal Tract Cross-Section Visualizer
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: SagittalVocalTractPainter(
                      tonguePosition: info['tonguePos'] as String,
                      isVoiced: isVoiced,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Text(
                          "Articulatory Placement: ${(info['tonguePos'] as String).replaceAll('_', ' ').toUpperCase()}",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isVoiced
                            ? const Color(0xFF8B5CF6).withOpacity(0.3)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isVoiced ? "⚡ Voiced (Vocal Cord Buzz)" : "💨 Unvoiced (Pure Airflow)",
                        style: TextStyle(
                          color: isVoiced ? const Color(0xFFC4B5FD) : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Actionable Physical Articulation Steps
          const Text(
            "How to produce this sound:",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...((info['instructions'] as List<String>).map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))),

          if (info.containsKey('commonMistake')) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFF87171)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Watch out: ${info['commonMistake']}",
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom 2D Sagittal Vocal Tract Cross-Section Painter
class SagittalVocalTractPainter extends CustomPainter {
  final String tonguePosition;
  final bool isVoiced;

  SagittalVocalTractPainter({
    required this.tonguePosition,
    required bool isVoiced,
  }) : isVoiced = isVoiced;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final palatePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final teethPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final tonguePaint = Paint()
      ..color = const Color(0xFFE11D48).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final tongueBorderPaint = Paint()
      ..color = const Color(0xFFFB7185)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Upper Palate & Jaw Profile
    final palatePath = Path();
    palatePath.moveTo(w * 0.15, h * 0.85); // Back of throat
    palatePath.quadraticBezierTo(w * 0.20, h * 0.35, w * 0.35, h * 0.28); // Soft palate
    palatePath.quadraticBezierTo(w * 0.55, h * 0.25, w * 0.70, h * 0.32); // Hard palate
    palatePath.quadraticBezierTo(w * 0.78, h * 0.38, w * 0.82, h * 0.48); // Alveolar ridge
    canvas.drawPath(palatePath, palatePaint);

    // 2. Upper Teeth
    canvas.drawLine(Offset(w * 0.82, h * 0.48), Offset(w * 0.82, h * 0.58), teethPaint);
    // Lower Teeth
    canvas.drawLine(Offset(w * 0.81, h * 0.76), Offset(w * 0.81, h * 0.68), teethPaint);

    // 3. Draw Tongue Contour based on target phoneme
    final tonguePath = Path();
    tonguePath.moveTo(w * 0.25, h * 0.85); // Tongue root

    if (tonguePosition == 'interdental') {
      // /θ/ or /ð/ - Tongue protrudes between upper and lower teeth
      tonguePath.cubicTo(
        w * 0.35, h * 0.75,
        w * 0.60, h * 0.65,
        w * 0.86, h * 0.63, // protruding between teeth
      );
      tonguePath.quadraticBezierTo(w * 0.84, h * 0.72, w * 0.78, h * 0.76);
    } else if (tonguePosition == 'retroflex') {
      // /ɜːr/ or /r/ - Tongue tip curled backward towards roof of mouth
      tonguePath.cubicTo(
        w * 0.35, h * 0.70,
        w * 0.55, h * 0.58,
        w * 0.62, h * 0.40, // tip curling up & back
      );
      tonguePath.quadraticBezierTo(w * 0.60, h * 0.68, w * 0.70, h * 0.76);
    } else if (tonguePosition == 'open_front') {
      // /æ/ - Tongue flattened low on mouth floor
      tonguePath.cubicTo(
        w * 0.35, h * 0.78,
        w * 0.55, h * 0.75,
        w * 0.78, h * 0.70, // low and forward
      );
      tonguePath.quadraticBezierTo(w * 0.75, h * 0.76, w * 0.68, h * 0.80);
    } else {
      // Default alveolar /t/, /d/, /s/ - Tongue near alveolar ridge
      tonguePath.cubicTo(
        w * 0.35, h * 0.75,
        w * 0.58, h * 0.60,
        w * 0.78, h * 0.50, // touching alveolar ridge
      );
      tonguePath.quadraticBezierTo(w * 0.72, h * 0.68, w * 0.68, h * 0.76);
    }

    tonguePath.lineTo(w * 0.25, h * 0.85);
    tonguePath.close();

    canvas.drawPath(tonguePath, tonguePaint);
    canvas.drawPath(tonguePath, tongueBorderPaint);

    // 4. Vocal Cord Vibration Glow (if voiced)
    if (isVoiced) {
      final vocalCordPaint = Paint()
        ..color = const Color(0xFFA855F7)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(w * 0.20, h * 0.82), 10, vocalCordPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SagittalVocalTractPainter oldDelegate) =>
      oldDelegate.tonguePosition != tonguePosition || oldDelegate.isVoiced != isVoiced;
}
