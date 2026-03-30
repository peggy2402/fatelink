import 'package:flutter/material.dart';

class ToastUtil {
  // Hiển thị Toast thông báo Thành Công (Xanh lá)
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      const Color(0xFF2E7D32),
      Icons.check_circle_outline,
    );
  }

  // Hiển thị Toast thông báo Lỗi (Đỏ bordeaux theo theme FateLink)
  static void showError(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFFBD114A), Icons.error_outline);
  }

  // Hiển thị Toast thông tin chung (Xanh biển sâu)
  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFF002B3D), Icons.info_outline);
  }

  // Hàm private xử lý giao diện chung cho Toast
  static void _showToast(
    BuildContext context,
    String message,
    Color bgColor,
    IconData icon,
  ) {
    // Ẩn Toast cũ nếu đang hiển thị để tránh bị đè hoặc chờ lâu
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor.withOpacity(
          0.95,
        ), // Hơi trong suốt tạo cảm giác hiện đại
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }
}
