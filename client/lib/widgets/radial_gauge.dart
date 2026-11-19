import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialScoreGaugeWidget extends StatelessWidget {
  final double overallScore;
  final double accuracy;
  final double fluency;
  final double prosody;
  final double completeness;

  const RadialScoreGaugeWidget({
    Key? key,
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.prosody,
    required this.completeness,
  }) : super(key: key);

  Color _getScoreColor(double score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final centerColor = _getScoreColor(overallScore);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Multi-Ring Radial Gauge Canvas
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(170, 170),
                  painter: MultiArcGaugePainter(
                    accuracy: accuracy,
                    fluency: fluency,
                    prosody: prosody,
                    completeness: completeness,
                  ),
                ),
                // Center Score Display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${overallScore.toInt()}",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: centerColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "PRON SCORE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Ring Legend Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGaugeLegend("Accuracy", "${accuracy.toInt()}%", const Color(0xFF10B981)),
              _buildGaugeLegend("Fluency", "${fluency.toInt()}%", const Color(0xFF6366F1)),
              _buildGaugeLegend("Prosody", "${prosody.toInt()}%", const Color(0xFF38BDF8)),
              _buildGaugeLegend("Complete", "${completeness.toInt()}%", const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeLegend(String title, String val, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class MultiArcGaugePainter extends CustomPainter {
  final double accuracy;
  final double fluency;
  final double prosody;
  final double completeness;

  MultiArcGaugePainter({
    required this.accuracy,
    required this.fluency,
    required this.prosody,
    required this.completeness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Rings from outer to inner
    _drawRing(canvas, center, radius: 76, strokeWidth: 5.5, progress: accuracy / 100.0, color: const Color(0xFF10B981));
    _drawRing(canvas, center, radius: 66, strokeWidth: 5.5, progress: fluency / 100.0, color: const Color(0xFF6366F1));
    _drawRing(canvas, center, radius: 56, strokeWidth: 5.5, progress: prosody / 100.0, color: const Color(0xFF38BDF8));
    _drawRing(canvas, center, radius: 46, strokeWidth: 5.5, progress: completeness / 100.0, color: const Color(0xFFF59E0B));
  }

  void _drawRing(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double strokeWidth,
    required double progress,
    required Color color,
  }) {
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant MultiArcGaugePainter oldDelegate) =>
      oldDelegate.accuracy != accuracy ||
      oldDelegate.fluency != fluency ||
      oldDelegate.prosody != prosody ||
      oldDelegate.completeness != completeness;
}
