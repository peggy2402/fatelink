import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter vẽ các vòng sóng âm 432Hz lan tỏa và vệ tinh linh hồn quanh quỹ đạo
class CosmicWavePainter extends CustomPainter {
  final double pulseValue;
  final double spinValue;
  final int phase;

  CosmicWavePainter({
    required this.pulseValue,
    required this.spinValue,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final maxRadius = size.width * 0.85;

    // Vẽ 3 vòng tròn sóng lan tỏa
    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulseValue + (i / 3.0)) % 1.0;
      final currentRadius = 60.0 + (waveProgress * (maxRadius - 60.0));
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.35;

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = (phase >= 2 ? const Color(0xFF00FFB2) : const Color(0xFFFF2A6D))
            .withValues(alpha: opacity);

      canvas.drawCircle(center, currentRadius, wavePaint);
    }

    // Vẽ các đốm vệ tinh linh hồn lướt quanh quỹ đạo
    if (phase >= 1) {
      final orbitRadius = size.width * 0.38;
      for (int i = 0; i < 3; i++) {
        final angle = (spinValue * 2 * math.pi) + (i * (2 * math.pi / 3));
        final nodePos = Offset(
          center.dx + math.cos(angle) * orbitRadius,
          center.dy + math.sin(angle) * orbitRadius,
        );

        // Hào quang vệ tinh
        final glowPaint = Paint()
          ..color = (phase >= 2 ? const Color(0xFF00FFB2) : const Color(0xFF00F0FF))
              .withValues(alpha: 0.35);
        canvas.drawCircle(nodePos, 8.0, glowPaint);

        // Tâm vệ tinh
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodePos, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CosmicWavePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.phase != phase;
  }
}
