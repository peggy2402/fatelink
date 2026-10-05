import 'package:flutter/foundation.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý huy hiệu số đếm (Badge Counter) trên icon ứng dụng (Home screen launcher)
class BadgeService {
  static const String _prefBadgeKey = 'fatelink_app_badge_count';
  static int _badgeCount = 0;

  static int get count => _badgeCount;

  /// Khởi tạo và đồng bộ badge count từ bộ nhớ cục bộ
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _badgeCount = prefs.getInt(_prefBadgeKey) ?? 0;
      if (_badgeCount > 0) {
        await _applyBadgeToLauncher(_badgeCount);
      }
    } catch (e) {
      debugPrint('⚠️ [BadgeService] Lỗi khởi tạo badge: $e');
    }
  }

  /// Cập nhật badge count tới một giá trị cụ thể
  static Future<void> setBadge(int count) async {
    _badgeCount = count < 0 ? 0 : count;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefBadgeKey, _badgeCount);
      await _applyBadgeToLauncher(_badgeCount);
      debugPrint('🔢 [BadgeService] Đã cập nhật badge: $_badgeCount');
    } catch (e) {
      debugPrint('⚠️ [BadgeService] Lỗi set badge: $e');
    }
  }

  /// Tăng số đếm badge khi có tin nhắn hoặc thông báo mới
  static Future<void> increment({int step = 1}) async {
    await setBadge(_badgeCount + step);
  }

  /// Giảm số đếm badge khi người dùng đọc tin nhắn
  static Future<void> decrement({int step = 1}) async {
    await setBadge(_badgeCount - step);
  }

  /// Xóa sạch số đếm badge (khi mở hộp thư hoặc vào phòng chat)
  static Future<void> clearBadge() async {
    await setBadge(0);
  }

  /// Áp dụng badge count lên Launcher của Android / iOS
  static Future<void> _applyBadgeToLauncher(int count) async {
    try {
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (e) {
      debugPrint('⚠️ [BadgeService] Thiết bị không hỗ trợ badge trực tiếp: $e');
    }
  }
}
