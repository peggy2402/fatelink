import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Nền Tinh Vân Cực Quang Vũ Trụ (Ambient Cosmic Aurora):
/// - Gradient Pearly Cosmic Twilight thanh khiết
/// - 3 Quầng sáng Ambient Glow (Indigo, Pink, Cyan)
/// - Lớp bụi sao vũ trụ lấp lánh (Starfield Particles)
class ExploreBackground extends StatelessWidget {
  final double width;
  final double height;

  const ExploreBackground({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Gradient nền chính
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFEEF2FF),
                Color(0xFFFFFFFF),
                Color(0xFFFDF2F8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 2. Quầng sáng Indigo góc trên trái
        Positioned(
          top: -40,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            ),
          ),
        ),

        // 3. Quầng sáng Pulse Pink góc giữa phải
        Positioned(
          top: height * 0.35,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEC4899).withValues(alpha: 0.10),
            ),
          ),
        ),

        // 4. Quầng sáng Cyan góc dưới trái
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            ),
          ),
        ),

        // 5. Bụi sao lấp lánh
        CustomPaint(
          size: Size(width, height),
          painter: _CosmicStarsPainter(),
        ),
      ],
    );
  }
}

class _CosmicStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(1337);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 0.8 + rng.nextDouble() * 1.5;
      final opacity = 0.15 + rng.nextDouble() * 0.35;

      paint.color = (i % 2 == 0 ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
          .withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
