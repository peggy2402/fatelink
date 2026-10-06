import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/router/app_router.dart';
import 'badge_service.dart';
import 'app_socket_service.dart';

/// Quản lý thông báo cục bộ (Local Notifications) và Notification Channels trên Android
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'fatelink_high_importance_channel';
  static const String channelName = 'Thông báo FateLink';
  static const String channelDescription =
      'Kênh thông báo tin nhắn và tương thích kết đôi từ FateLink';

  static bool _isInitialized = false;

  /// Khởi tạo Notification Plugin và thiết lập Android Notification Channel
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Cấu hình icon mặc định cho Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Cấu hình cho iOS/Darwin (sẵn sàng khi dùng iOS)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Tạo Notification Channel với mức ưu tiên tối đa (Importance.max)
    // Giúp thông báo hiển thị dạng Heads-up (nổi trên màn hình) và xuất hiện ở Màn hình khóa (Lock screen)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final AndroidNotificationChannel highImportanceChannel =
          AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        showBadge: true,
        enableVibration: true,
        playSound: true,
        vibrationPattern: Int64List.fromList([0, 250, 200, 250]),
      );

      await androidImplementation.createNotificationChannel(
        highImportanceChannel,
      );
      debugPrint('🔔 [NotificationService] Đã tạo Android Notification Channel: $channelId');
    }

    _isInitialized = true;
  }

  /// Hiển thị thông báo đẩy lên thanh trạng thái, màn hình khóa & heads-up banner
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    int? badgeCount,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Tự động đồng bộ badge count nếu được truyền vào
    if (badgeCount != null) {
      await BadgeService.setBadge(badgeCount);
    }

    // Chi tiết cấu hình cho Android: Ưu tiên cao nhất, hiển thị màn hình khóa
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Tin nhắn mới',
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C5CE7), // Màu tím Cosmic của FateLink
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public, // Cho phép hiển thị đầy đủ trên màn hình khóa
      number: badgeCount ?? BadgeService.count, // Hiển thị số đếm badge trên các launcher hỗ trợ
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 200, 250]),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'FateLink',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Xử lý khi người dùng chạm vào thông báo trên thanh trạng thái hoặc màn hình khóa
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👉 [NotificationService] Người dùng chạm thông báo: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) return;

    try {
      String? partnerId;
      // Kiểm tra nếu payload là JSON
      if (response.payload!.startsWith('{')) {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        if (data['type'] == 'incoming_voice_call') {
          AppSocketService.instance.initialize();
          return;
        }
        partnerId = data['partnerId'] ?? data['senderId'];
      } else {
        partnerId = response.payload;
      }

      if (partnerId != null && partnerId.isNotEmpty) {
        // Xóa hoặc giảm badge khi mở tin nhắn
        BadgeService.clearBadge();

        AppRouter.navigatorKey.currentState?.pushNamed(
          '/match-chat',
          arguments: partnerId,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Lỗi xử lý điều hướng thông báo: $e');
    }
  }

  /// Hủy một thông báo cụ thể
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Hủy tất cả thông báo
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
