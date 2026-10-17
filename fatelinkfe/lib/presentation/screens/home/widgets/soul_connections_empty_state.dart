import 'package:flutter/material.dart';

class SoulConnectionsEmptyState extends StatelessWidget {
  final VoidCallback onResetFilter;

  const SoulConnectionsEmptyState({
    super.key,
    required this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 38,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa tìm thấy tần số phù hợp',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử nới lỏng bán kính khoảng cách hoặc mở rộng độ tuổi để tìm thấy nhiều bạn đồng điệu hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onResetFilter,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Đặt lại bộ lọc',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
