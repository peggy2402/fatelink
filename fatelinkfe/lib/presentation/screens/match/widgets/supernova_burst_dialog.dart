import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';

/// Modal chúc mừng Siêu Tân Tinh (SupernovaBurstDialog):
/// - Bùng nổ hạt ánh sao
/// - Gỡ bỏ 120s vĩnh viễn
/// - Nút tiếp tục trò chuyện dài hạn
class SupernovaBurstDialog extends StatelessWidget {
  final MatchUser partner;
  final VoidCallback onContinue;

  const SupernovaBurstDialog({
    super.key,
    required this.partner,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1335),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Column(
        children: [
          Text('✨💖✨', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            'KẾT NỐI ĐỊNH MỆNH!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cả hai bạn đã cùng chạm tim! Mọi bí ẩn sương mù đã được gỡ bỏ, và giới hạn 120 giây đã bị phá vỡ vĩnh viễn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: partner.avatar != null && partner.avatar!.isNotEmpty
                      ? Image.network(
                          partner.avatar!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Container(width: 44, height: 44, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tương hợp: ${partner.compatibilityScore}%',
                        style: const TextStyle(
                          color: Color(0xFF00FFB2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF2A6D),
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onContinue,
          child: const Text(
            'Tiếp tục trò chuyện vĩnh viễn 🚀',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter vẽ các hạt ánh sáng bùng nổ Siêu Tân Tinh (Supernova Particle Explosion)
class SupernovaPainter extends CustomPainter {
  final double progress;

  SupernovaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxRadius = size.width * 0.9;
    const particleCount = 45;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * (2 * math.pi / particleCount));
      final distance = progress * maxRadius * (0.6 + (i % 5) * 0.1);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFFFF2A6D) : const Color(0xFF00F0FF))
            .withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), (4.0 * (1.0 - progress * 0.5)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SupernovaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
