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
    _showToast(context, message, const Color(0xFFBD114A), Icons.info_outline);
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
        // 1. Làm cho SnackBar gốc trở nên vô hình
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 2. Animate toàn bộ nội dung bên trong để mô phỏng khối Toast trượt xuống
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              // Hiệu ứng mờ dần (FadeIn)
              opacity: value,
              child: Transform.translate(
                // Hiệu ứng trượt từ trên xuống
                offset: Offset(0, (1 - value) * -30),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
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
          ),
        ),
        behavior: SnackBarBehavior.floating,
        // Đẩy SnackBar lên trên cùng
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero, // Xóa padding mặc định của SnackBar
      ),
    );
  }
}
