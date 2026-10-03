import 'package:flutter/material.dart';

/// BottomSheet tùy chọn cho màn hình Match Chat (Báo cáo & Hủy ghép đôi)
class MatchOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onUnmatch;

  const MatchOptionsBottomSheet({
    super.key,
    required this.onReport,
    required this.onUnmatch,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onReport,
    required VoidCallback onUnmatch,
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
              Icons.report_problem_outlined,
              color: Colors.orange,
            ),
            title: const Text(
              'Báo cáo người dùng',
              style: TextStyle(color: Colors.white),
            ),
            onTap: onReport,
          ),
          ListTile(
            leading: const Icon(
              Icons.person_remove_outlined,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Hủy ghép đôi (Unmatch)',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: onUnmatch,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
