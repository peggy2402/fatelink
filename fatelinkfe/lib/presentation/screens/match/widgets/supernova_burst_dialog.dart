import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../data/models/match_user.dart';

/// Modal chúc mừng Siêu Tân Tinh (SupernovaBurstDialog):
/// - Bùng nổ hạt ánh sao
/// - Gỡ bỏ 120s vĩnh viễn
/// - Nút tiếp tục trò chuyện chuẩn Cosmic Design System
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16102B).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Emoji & Tiêu đề
            const Text('✨💖✨', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            const Text(
              'KẾT NỐI ĐỊNH MỆNH!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // 2. Nội dung thông điệp
            Text(
              'Cả hai bạn đã cùng chạm tim! Mọi bí ẩn sương mù đã được gỡ bỏ, và giới hạn 120 giây đã bị phá vỡ vĩnh viễn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // 3. Card thông tin bạn bè đã mở khóa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnonymousAvatarHelper.buildAvatar(
                    user: partner,
                    size: 48,
                    showLockBadge: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.name.isNotEmpty
                              ? partner.name
                              : partner.displayName,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Tương hợp: ${partner.compatibilityScore}%',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                color: Color(0xFF10B981),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 4. Nút bấm CTA: Tiếp tục trò chuyện vĩnh viễn (Chuẩn Cosmic Design & không rớt dòng)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onContinue();
                },
                borderRadius: BorderRadius.circular(25),
                child: Ink(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Tiếp tục trò chuyện vĩnh viễn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ],
                    ),
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
