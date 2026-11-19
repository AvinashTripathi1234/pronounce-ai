import 'package:flutter/material.dart';
import '../models/phoneme_feedback.dart';
import 'radial_gauge.dart';

class ScoreCardWidget extends StatelessWidget {
  final PronunciationFeedback feedback;
  final VoidCallback? onRetry;
  final VoidCallback? onNext;

  const ScoreCardWidget({
    Key? key,
    required this.feedback,
    this.onRetry,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Multi-Arc Radial Score Gauge
        RadialScoreGaugeWidget(
          overallScore: feedback.overallScore,
          accuracy: feedback.accuracy,
          fluency: feedback.fluency,
          prosody: feedback.prosody,
          completeness: feedback.completeness,
        ),

        const SizedBox(height: 16),

        // Actionable Coaching Advice
        if (feedback.tips.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.psychology, size: 16, color: Color(0xFFFACC15)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "AI Articulation Coach",
                      style: TextStyle(
                        color: Color(0xFFFACC15),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...feedback.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.arrow_right, size: 16, color: Color(0xFFFACC15)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
