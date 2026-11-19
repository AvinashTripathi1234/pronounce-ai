import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioVisualizerWidget extends StatefulWidget {
  final bool isRecording;

  const AudioVisualizerWidget({Key? key, required this.isRecording}) : super(key: key);

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 18;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            double height = 6.0;
            if (widget.isRecording) {
              // Generate rhythmic organic waveform fluctuation
              final phase = (index / barCount) * 2 * math.pi;
              final t = _controller.value * 2 * math.pi;
              final wave = (math.sin(t + phase) + 1.0) / 2.0;
              height = 8.0 + (wave * 34.0);
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4.0,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: widget.isRecording
                      ? [const Color(0xFF6366F1), const Color(0xFF38BDF8)]
                      : [Colors.white24, Colors.white12],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
