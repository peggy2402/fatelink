import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../data/models/match_user.dart';

class CosmicWidgetService {
  CosmicWidgetService._();
  static final CosmicWidgetService instance = CosmicWidgetService._();

  static const String appGroupId = 'group.com.fatelink.app';
  static const String androidWidgetName = 'CosmicSoulmateWidgetProvider';
  static const String iOSWidgetName = 'CosmicSoulmateGlanceWidget';

  /// Khởi tạo cấu hình AppGroup và đăng ký callback
  Future<void> initialize({Function(Uri? uri)? onWidgetClick}) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      // Kiểm tra xem ứng dụng có được mở từ Widget không
      final launchedUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launchedUri != null && onWidgetClick != null) {
        onWidgetClick(launchedUri);
      }

      // Lắng nghe sự kiện click khi ứng dụng đang chạy nền
      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null && onWidgetClick != null) {
          onWidgetClick(uri);
        }
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo CosmicWidgetService: $e');
    }
  }

  /// Cập nhật thông tin tri kỷ tâm hồn mới nhất lên Widget màn hình chính
  Future<void> updateSoulmateGlance({
    required String name,
    required String vibe,
    required String harmony,
    required String distance,
    String headline = '✦ FATELINK 432Hz',
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('headline', headline);
      await HomeWidget.saveWidgetData<String>('soulmate_name', name);
      await HomeWidget.saveWidgetData<String>('soulmate_vibe', vibe);
      await HomeWidget.saveWidgetData<String>('soulmate_harmony', harmony);
      await HomeWidget.saveWidgetData<String>('soulmate_distance', distance);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      debugPrint('Đã cập nhật dữ liệu tiện ích Cosmic Widget thành công');
    } catch (e) {
      debugPrint('Lỗi cập nhật tiện ích Cosmic Widget: $e');
    }
  }

  /// Cập nhật trực tiếp từ một MatchUser
  Future<void> updateFromMatchUser(MatchUser user) async {
    final displayName = user.name.isNotEmpty ? user.name : user.anonymousName;
    final harmony = '${user.compatibilityScore}% Hòa âm';
    final distance = (user.distanceKm != null && user.distanceKm! > 0)
        ? '📍 Cách bạn ${user.distanceKm!.toStringAsFixed(1)} km'
        : '📍 Đang ở gần bạn';
    final vibe = user.emotion.isNotEmpty ? user.emotion : 'Đang hòa âm cảm xúc';

    await updateSoulmateGlance(
      name: displayName,
      vibe: vibe,
      harmony: harmony,
      distance: distance,
    );
  }
}
