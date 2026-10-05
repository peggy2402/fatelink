import 'package:flutter/material.dart';

/// Trạng thái trống khi tìm kiếm hoặc lọc không có kết quả trong Chat (ChatEmptyState)
class ChatEmptyState extends StatelessWidget {
  final VoidCallback? onResetFilter;

  const ChatEmptyState({
    super.key,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Không tìm thấy cuộc trò chuyện nào',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thử tìm kiếm với từ khóa khác hoặc bấm dấu "+" để tạo kết nối mới.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
