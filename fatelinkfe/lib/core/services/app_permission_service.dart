import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý và xin cấp quyền người dùng một cách thân thiện
class AppPermissionService {
  AppPermissionService._();

  static const String _hasRequestedLocationKey = 'has_requested_location_permission';

  /// Kiểm tra và xin quyền vị trí lần đầu khi cài app
  static Future<bool> checkAndRequestInitialPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool(_hasRequestedLocationKey) ?? false;

    final locationStatus = await Permission.locationWhenInUse.status;

    if (locationStatus.isGranted) {
      return true;
    }

    if (!hasAsked && context.mounted) {
      final shouldRequest = await showLocationPermissionDialog(context);
      await prefs.setBool(_hasRequestedLocationKey, true);

      if (shouldRequest == true) {
        final result = await Permission.locationWhenInUse.request();
        // Đồng thời xin cấp quyền thông báo đẩy để không bỏ lỡ tin nhắn & lượt ghép đôi
        await Permission.notification.request();
        return result.isGranted;
      }
    }

    return false;
  }

  /// Hộp thoại giải thích quyền vị trí trực quan, thân thiện
  static Future<bool?> showLocationPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Vị trí với hiệu ứng phát sáng Cosmic
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                const Text(
                  'Bật định vị tìm bạn đồng điệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Nội dung giải thích
                const Text(
                  'Meyu cần quyền truy cập vị trí để tìm kiếm những người có cùng tần số cảm xúc xung quanh bạn và đo khoảng cách kết nối chính xác.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Nút hành động
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Để sau',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'Cho phép định vị',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Xin quyền Camera (quét mã QR)
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Xin quyền Thư viện ảnh (đổi avatar / ảnh vibe)
  static Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Xin quyền Thông báo (Push Notification)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
