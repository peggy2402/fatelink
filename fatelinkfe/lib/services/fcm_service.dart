import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static const _secureStorage = FlutterSecureStorage();

  // Thêm callback onNavigateToChat để xử lý việc chuyển trang khi bấm vào thông báo
  static Future<void> initialize({
    Function(String partnerId)? onNavigateToChat,
  }) async {
    // 1. Yêu cầu quyền hiển thị thông báo (Bắt buộc trên iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Đã cấp quyền Push Notification');

      // 2. Lấy Device Token hiện tại
      String? token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');

      if (token != null) {
        await sendTokenToBackend(token);
      }

      // 3. Lắng nghe nếu hệ thống đổi token mới
      _firebaseMessaging.onTokenRefresh.listen(sendTokenToBackend);

      // 4. Bắt sự kiện nhận thông báo khi app ĐANG MỞ (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Nhận thông báo: ${message.notification?.title}');

        // Hiển thị Toast mượt mà ở cạnh trên màn hình
        Fluttertoast.showToast(
          msg:
              "💬 ${message.notification?.title ?? 'Thông báo'}: ${message.notification?.body ?? ''}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.9),
          textColor: Colors.white,
        );
      });

      // 5. Bắt sự kiện bấm vào thông báo khi app ĐANG CHẠY NỀN (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 Bấm thông báo (Background): ${message.data}');
        if (message.data.containsKey('senderId') && onNavigateToChat != null) {
          onNavigateToChat(message.data['senderId']);
        }
      });

      // 6. Bắt sự kiện bấm vào thông báo khi app ĐÃ TẮT HOÀN TOÀN (Terminated)
      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('🚀 Bấm thông báo (Terminated): ${message.data}');
          if (message.data.containsKey('senderId') &&
              onNavigateToChat != null) {
            onNavigateToChat(message.data['senderId']);
          }
        }
      });
    }
  }

  // Hàm gửi Device Token lên NestJS Backend
  static Future<void> sendTokenToBackend(String fcmToken) async {
    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      if (accessToken == null) return; // Chưa đăng nhập thì không gửi

      final response = await http.post(
        Uri.parse(
          'https://fatelink-be.fly.dev/api/users/fcm-token',
        ), // URL Backend
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (e) {
      debugPrint('❌ Lỗi gửi FCM Token: $e');
    }
  }
}
