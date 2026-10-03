import 'package:flutter/material.dart';

/// Huy hiệu đồng hồ đếm ngược định mệnh 120s (SoulCountdownBadge):
/// - Hiển thị mm:ss với icon đồng hồ cát
/// - Đổi sang màu hồng đỏ nhấp nháy cảnh báo khi còn dưới 30s
/// - Chuyển sang biểu tượng vô hạn (∞) khi kết nối thành công vĩnh viễn
class SoulCountdownBadge extends StatelessWidget {
  final int remainingSeconds;
  final bool isUnlockedForever;

  const SoulCountdownBadge({
    super.key,
    required this.remainingSeconds,
    required this.isUnlockedForever,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = remainingSeconds <= 30 && !isUnlockedForever;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFFF2A6D).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFF2A6D)
              : const Color(0xFF00FFB2).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlockedForever
                ? Icons.all_inclusive_rounded
                : Icons.hourglass_top_rounded,
            color: isUrgent ? const Color(0xFFFF2A6D) : const Color(0xFF00FFB2),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isUnlockedForever ? 'VÔ HẠN' : '$minutes:$seconds',
            style: TextStyle(
              color: isUrgent ? const Color(0xFFFF2A6D) : const Color(0xFF00FFB2),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
