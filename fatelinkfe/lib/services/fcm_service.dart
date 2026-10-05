import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:fatelinkfe/core/utils/secure_storage_helper.dart';
import 'package:fatelinkfe/services/api_service.dart';
import 'package:fatelinkfe/core/router/app_router.dart';
import 'badge_service.dart';
import 'notification_service.dart';

/// Top-level background message handler bắt buộc cho FCM Android
/// Chạy trong một isolate độc lập khi app đang ở chế độ chạy ngầm (Background) hoặc đã tắt (Terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔔 [FCM Background] Đã nhận thông báo ngầm: ${message.messageId} - ${message.data}');
    
    // Tự động tăng số đếm badge khi nhận tin nhắn ngầm
    await BadgeService.initialize();
    await BadgeService.increment();
  } catch (e) {
    debugPrint('⚠️ [FCM Background] Lỗi background handler: $e');
  }
}

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static const _secureStorage = SecureStorageHelper.storage;

  /// Khởi tạo toàn diện FCM, Notification Channel và Badge Service
  static Future<void> initialize({
    Function(String partnerId)? onNavigateToChat,
  }) async {
    try {
      // 1. Khởi tạo Notification Channel và Badge counter
      await NotificationService.initialize();
      await BadgeService.initialize();

      // 2. Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Yêu cầu quyền hiển thị thông báo đẩy (Hỗ trợ Android 13+ và iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 [FcmService] Trạng thái quyền thông báo: ${settings.authorizationStatus}');

      // 4. Lấy Device Token hiện tại
      String? token = await _firebaseMessaging.getToken();
      debugPrint('📱 [FcmService] FCM Token: $token');

      if (token != null) {
        await sendTokenToBackend(token);
      }

      // 5. Lắng nghe nếu hệ thống thay đổi token mới
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 [FcmService] Token làm mới: $newToken');
        sendTokenToBackend(newToken);
      });

      // 6. Bắt sự kiện nhận thông báo khi app ĐANG MỞ (Foreground)
      // Khi app đang mở, FCM Android mặc định KHÔNG hiện pop-up/heads-up,
      // vì vậy chúng ta dùng NotificationService để bắn Heads-up notification và cập nhật badge
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 [FcmService] Nhận tin nhắn Foreground: ${message.notification?.title ?? message.data['title']}');

        // Tăng badge số đếm trên icon ứng dụng
        await BadgeService.increment();

        final title = message.notification?.title ??
            message.data['title'] ??
            'FateLink';
        final body = message.notification?.body ??
            message.data['body'] ??
            'Bạn có tin nhắn mới';

        // Hiển thị Heads-Up Notification nổi trên đầu màn hình & màn hình khóa
        await NotificationService.showNotification(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
          badgeCount: BadgeService.count,
        );
      });

      // 7. Bắt sự kiện bấm vào thông báo khi app ĐANG CHẠY NỀN (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FcmService] Bấm thông báo (Background): ${message.data}');
        _handleNotificationClick(message.data, onNavigateToChat);
      });

      // 8. Bắt sự kiện bấm vào thông báo khi app ĐÃ TẮT HOÀN TOÀN (Terminated)
      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('🚀 [FcmService] Bấm thông báo (Terminated): ${message.data}');
          _handleNotificationClick(message.data, onNavigateToChat);
        }
      });
    } catch (e) {
      debugPrint('⚠️ [FcmService] Lỗi khởi tạo FCM: $e');
    }
  }

  /// Điều hướng tới phòng chat và xóa số đếm badge khi bấm thông báo
  static void _handleNotificationClick(
    Map<String, dynamic> data,
    Function(String partnerId)? onNavigateToChat,
  ) {
    // Đã mở tin nhắn -> Reset badge icon app
    BadgeService.clearBadge();

    final partnerId = data['partnerId'] ?? data['senderId'];
    if (partnerId != null && partnerId.toString().isNotEmpty) {
      if (onNavigateToChat != null) {
        onNavigateToChat(partnerId.toString());
      } else {
        AppRouter.navigatorKey.currentState?.pushNamed(
          '/match-chat',
          arguments: partnerId.toString(),
        );
      }
    }
  }

  /// Gửi Device Token lên NestJS Backend để lưu trữ phục vụ push notification
  static Future<void> sendTokenToBackend(String fcmToken) async {
    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      if (accessToken == null) return; // Chưa đăng nhập thì lưu tạm, sẽ gửi khi đăng nhập xong
      final urlEndpoints = '${AppConstants.baseUrl}/${AppConstants.updateFcmToken}';
      final uri = Uri.parse(urlEndpoints);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      final body = {'fcmToken': fcmToken};
      await ApiService.executeWithLogging(
        method: 'POST',
        uri: uri,
        headers: headers,
        body: body,
        requestFn: () => http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ),
      );
      debugPrint('✅ [FcmService] Đã gửi FCM Token lên server thành công');
    } catch (e) {
      debugPrint('❌ [FcmService] Lỗi gửi FCM Token lên backend: $e');
    }
  }
}
