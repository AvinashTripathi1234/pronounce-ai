import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProsodyRibbonWidget extends StatelessWidget {
  final double prosodyScore;
  final String sentence;

  const ProsodyRibbonWidget({
    Key? key,
    required this.prosodyScore,
    required this.sentence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.waves, size: 18, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text(
                    "Pitch & Prosody Contour",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${prosodyScore.toInt()}% Intonation Match",
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pitch Contour Canvas
          SizedBox(
            width: double.infinity,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                size: const Size(double.infinity, 90),
                painter: PitchContourPainter(prosodyScore: prosodyScore),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(color: const Color(0xFF38BDF8), label: "Native Target Pitch"),
              const SizedBox(width: 18),
              _buildLegend(
                color: prosodyScore >= 80
                    ? const Color(0xFF10B981)
                    : (prosodyScore >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                label: "Your Spoken Pitch",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class PitchContourPainter extends CustomPainter {
  final double prosodyScore;

  PitchContourPainter({required this.prosodyScore});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw Subtle Gridlines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.33), Offset(w, h * 0.33), gridPaint);
    canvas.drawLine(Offset(0, h * 0.66), Offset(w, h * 0.66), gridPaint);

    // 1. Draw Native Pitch Contour (Ideal inflection curve with natural sentence stress peaks)
    final nativePath = Path();
    nativePath.moveTo(w * 0.05, h * 0.65);
    nativePath.cubicTo(w * 0.25, h * 0.25, w * 0.40, h * 0.70, w * 0.60, h * 0.30);
    nativePath.cubicTo(w * 0.75, h * 0.20, w * 0.88, h * 0.60, w * 0.95, h * 0.75);

    final nativePaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(nativePath, nativePaint);

    // 2. Draw User's Spoken Pitch Contour
    // Simulates close tracking for high score, flatter or divergent tracking for lower score
    final userPath = Path();
    userPath.moveTo(w * 0.05, h * (prosodyScore >= 80 ? 0.64 : 0.60));

    final variance = (100.0 - prosodyScore) * 0.25;
    userPath.cubicTo(
      w * 0.25, h * (0.25 + (variance / 100)),
      w * 0.40, h * (0.70 - (variance / 120)),
      w * 0.60, h * (0.32 + (variance / 90)),
    );
    userPath.cubicTo(
      w * 0.75, h * (0.22 + (variance / 80)),
      w * 0.88, h * 0.62,
      w * 0.95, h * (prosodyScore >= 80 ? 0.73 : 0.55),
    );

    final userColor = prosodyScore >= 80
        ? const Color(0xFF10B981)
        : (prosodyScore >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    final userPaint = Paint()
      ..color = userColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(userPath, userPaint);

    // Glow under user curve
    final glowPaint = Paint()
      ..color = userColor.withOpacity(0.15)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(userPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant PitchContourPainter oldDelegate) =>
      oldDelegate.prosodyScore != prosodyScore;
}
