import 'package:flutter/material.dart';

/// BottomSheet tùy chọn cho màn hình Match Chat (Báo cáo, Hủy ghép đôi & Chặn)
class MatchOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onUnmatch;
  final VoidCallback onBlock;

  const MatchOptionsBottomSheet({
    super.key,
    required this.onReport,
    required this.onUnmatch,
    required this.onBlock,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onReport,
    required VoidCallback onUnmatch,
    required VoidCallback onBlock,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MatchOptionsBottomSheet(
        onReport: onReport,
        onUnmatch: onUnmatch,
        onBlock: onBlock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.flag_outlined,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            title: const Text(
              'Báo cáo vi phạm',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: const Text(
              'Gửi phản ánh nếu người này vi phạm quy tắc cộng đồng',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
            onTap: onReport,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.heart_broken_outlined,
                color: Color(0xFFE11D48),
                size: 20,
              ),
            ),
            title: const Text(
              'Hủy ghép đôi (Unmatch / Bỏ thích)',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBE123C),
              ),
            ),
            subtitle: const Text(
              'Thu hồi danh tính thật và đóng cuộc trò chuyện 1-1',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
            onTap: onUnmatch,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            title: const Text(
              'Chặn người dùng này',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            subtitle: const Text(
              'Cả hai sẽ không thể tìm thấy, nhắn tin hay kết nối lại',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
            onTap: onBlock,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
