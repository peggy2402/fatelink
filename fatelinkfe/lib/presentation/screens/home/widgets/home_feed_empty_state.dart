import 'package:flutter/material.dart';

/// Trạng thái trống của Feed trang chủ (HomeFeedEmptyState):
/// - Tách rời gọn gàng, hiển thị khi chưa có người dùng phù hợp hoặc đang lọc
class HomeFeedEmptyState extends StatelessWidget {
  final bool isFiltered;
  final double bottomSafePadding;
  final VoidCallback onResetFilter;
  final VoidCallback onStartChat;

  const HomeFeedEmptyState({
    super.key,
    required this.isFiltered,
    required this.bottomSafePadding,
    required this.onResetFilter,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: bottomSafePadding + 20,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            ),
            child: Center(
              child: Icon(
                isFiltered
                    ? Icons.filter_alt_off_rounded
                    : Icons.radar_rounded,
                color: const Color(0xFF6366F1),
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? 'Chưa có ai phù hợp bộ lọc'
                : 'Chưa có tín hiệu xung quanh',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Hiện tại chưa có người dùng nào khớp với tiêu chí bạn chọn. Hãy thử nới lỏng bộ lọc nhé!'
                : 'Bạn đang là người duy nhất phát sóng bước sóng hôm nay! Khi có người dùng thật khác tham gia, họ sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (isFiltered)
            ElevatedButton.icon(
              onPressed: onResetFilter,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
              label: const Text(
                'Đặt lại bộ lọc',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              label: const Text(
                'Tâm sự cùng Faye AI',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}
