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
      backgroundColor: const Color(0xFF131526),
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
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(
              Icons.flag_outlined,
              color: Color(0xFFF59E0B),
            ),
            title: const Text(
              'Báo cáo vi phạm',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            subtitle: const Text(
              'Gửi phản ánh nếu người này vi phạm quy tắc cộng đồng',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
              ),
            ),
            onTap: onReport,
          ),
          ListTile(
            leading: const Icon(
              Icons.heart_broken_outlined,
              color: Color(0xFFF43F5E),
            ),
            title: const Text(
              'Hủy ghép đôi (Unmatch / Bỏ thích)',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFDA4AF),
              ),
            ),
            subtitle: const Text(
              'Thu hồi danh tính thật và đóng cuộc trò chuyện 1-1',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
              ),
            ),
            onTap: onUnmatch,
          ),
          ListTile(
            leading: const Icon(
              Icons.block_rounded,
              color: Color(0xFFEF4444),
            ),
            title: const Text(
              'Chặn người dùng này',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
            subtitle: const Text(
              'Cả hai sẽ không thể tìm thấy, nhắn tin hay kết nối lại',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
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
