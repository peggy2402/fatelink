import 'package:flutter/material.dart';

class BroadcastCenterCore extends StatelessWidget {
  final double coreSize;
  final AnimationController pulseController;
  final String? myAvatarUrl;
  final String currentMood;
  final String frequency;

  const BroadcastCenterCore({
    super.key,
    required this.coreSize,
    required this.pulseController,
    this.myAvatarUrl,
    required this.currentMood,
    required this.frequency,
  });

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFF261845),
      child: const Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Color(0xFFFF5E97),
          size: 38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: coreSize * 2.4,
      height: coreSize * 2.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quầng sáng phát quang nền
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, _) {
              final scale = 1.0 + (pulseController.value * 0.25);
              final opacity = (1.0 - pulseController.value).clamp(0.0, 1.0) * 0.45;
              return Container(
                width: coreSize * 1.8 * scale,
                height: coreSize * 1.8 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF2A6D).withValues(alpha: opacity),
                ),
              );
            },
          ),

          // Vòng tròn hào quang Neon
          Container(
            width: coreSize + 16,
            height: coreSize + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2A6D), Color(0xFF00F0FF), Color(0xFF9D00FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withValues(alpha: 0.6),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Avatar trung tâm
          Container(
            width: coreSize,
            height: coreSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF131127),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: myAvatarUrl != null && myAvatarUrl!.isNotEmpty
                  ? Image.network(
                      myAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),

          // Huy hiệu tần số bên dưới avatar
          Positioned(
            bottom: coreSize * 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00FFB2).withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFB2).withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF00FFB2),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$currentMood • $frequency',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
