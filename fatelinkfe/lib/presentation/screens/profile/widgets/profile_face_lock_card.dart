import 'package:flutter/material.dart';

class ProfileFaceLockCard extends StatelessWidget {
  final bool isFaceLocked;
  final ValueChanged<bool> onToggle;

  const ProfileFaceLockCard({
    super.key,
    required this.isFaceLocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFaceLocked
              ? const Color(0xFFEC4899).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isFaceLocked
                ? const Color(0xFFEC4899).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFaceLocked
                        ? [const Color(0xFFEC4899), const Color(0xFFF43F5E)]
                        : [const Color(0xFFEC4899), const Color(0xFF6366F1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFaceLocked
                              ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                              : const Color(0xFF6366F1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFaceLocked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: isFaceLocked
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isFaceLocked
                                  ? 'Khóa diện mạo cá nhân (Đang bật)'
                                  : 'Khóa diện mạo cá nhân (Đang tắt)',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontWeight: FontWeight.w800,
                                color: isFaceLocked
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF0F172A),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isFaceLocked
                                  ? '🔒 Đang ẩn danh: Người khác sẽ KHÔNG THỂ xem Tên thật, Avatar và Vibes của bạn kể cả khi hai người đã theo dõi nhau.'
                                  : '✨ Mặc định: Avatar, Tên thật & Vibes sẽ tự động mở khóa ngay khi cả hai người cùng thả tim / theo dõi nhau.',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isFaceLocked,
                        activeTrackColor: const Color(0xFFEC4899),
                        onChanged: onToggle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
