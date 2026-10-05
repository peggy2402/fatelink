import 'package:flutter/material.dart';

/// Nền vũ trụ Cosmic mượt mà (Zero GPU Overhead):
/// - Sử dụng RadialGradient chuyển màu tự nhiên thay thế cho BackdropFilter(sigma: 90)
/// - Giúp máy Android (Samsung, Xiaomi, Oppo...) cuộn 120 FPS không bị drop frame/khựng
class HomeCosmicBackground extends StatelessWidget {
  const HomeCosmicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Ánh sáng Neon Magenta mờ góc trên trái
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x35EC4899),
                      Color(0x18EC4899),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Ánh sáng Soft Indigo mờ ở giữa bên phải
            Positioned(
              top: 240,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x286366F1),
                      Color(0x126366F1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Ánh sáng Cyan Neon mờ góc dưới trái
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x2500E5FF),
                      Color(0x1000E5FF),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
