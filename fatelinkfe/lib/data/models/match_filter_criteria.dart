import 'package:flutter/material.dart';
import 'match_user.dart';

class MatchFilterCriteria {
  final String gender; // 'all', 'female', 'male'
  final RangeValues ageRange;
  final String locationScope; // 'all', 'nearby', 'city', 'custom'
  final double maxDistanceKm; // Dùng khi locationScope == 'custom'
  final String? emotion; // null hoặc tên cảm xúc
  final bool onlineOnly;

  const MatchFilterCriteria({
    this.gender = 'all',
    this.ageRange = const RangeValues(18, 45),
    this.locationScope = 'all',
    this.maxDistanceKm = 50.0,
    this.emotion,
    this.onlineOnly = false,
  });

  /// Kiểm tra xem bộ lọc có đang ở trạng thái mặc định không
  bool get isDefault =>
      gender == 'all' &&
      ageRange.start <= 18 &&
      ageRange.end >= 45 &&
      locationScope == 'all' &&
      (emotion == null || emotion == 'all') &&
      !onlineOnly;

  /// Đếm số tiêu chí tùy chỉnh đang kích hoạt
  int get activeFilterCount {
    int count = 0;
    if (gender != 'all') count++;
    if (ageRange.start > 18 || ageRange.end < 45) count++;
    if (locationScope != 'all') count++;
    if (emotion != null && emotion != 'all') count++;
    if (onlineOnly) count++;
    return count;
  }

  MatchFilterCriteria copyWith({
    String? gender,
    RangeValues? ageRange,
    String? locationScope,
    double? maxDistanceKm,
    String? emotion,
    bool? onlineOnly,
  }) {
    return MatchFilterCriteria(
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      locationScope: locationScope ?? this.locationScope,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      emotion: emotion ?? this.emotion,
      onlineOnly: onlineOnly ?? this.onlineOnly,
    );
  }

  /// Áp dụng bộ lọc lên danh sách người dùng tương thích
  List<MatchUser> apply(List<MatchUser> users, {String searchQuery = ''}) {
    final query = searchQuery.trim().toLowerCase();

    return users.where((u) {
      // 1. Tìm kiếm theo từ khóa (nếu có): tên, bí danh, cảm xúc, hashtag
      if (query.isNotEmpty) {
        final nameMatch = u.displayName.toLowerCase().contains(query);
        final emotionMatch = u.emotion.toLowerCase().contains(query);
        final tagMatch = u.tags?.any((t) => t.toLowerCase().contains(query)) ?? false;
        if (!nameMatch && !emotionMatch && !tagMatch) {
          return false;
        }
      }

      // 2. Lọc theo Giới tính
      if (gender != 'all') {
        if (u.resolvedGender != gender) return false;
      }

      // 3. Lọc theo Độ tuổi
      final userAge = u.resolvedAge;
      if (userAge < ageRange.start.round() || userAge > ageRange.end.round()) {
        return false;
      }

      // 4. Lọc theo Cự ly / Khu vực
      final dist = u.distanceKm ?? 999.0;
      if (locationScope == 'nearby') {
        if (dist > 5.0) return false;
      } else if (locationScope == 'city') {
        if (dist > 25.0) return false;
      } else if (locationScope == 'custom') {
        if (dist > maxDistanceKm) return false;
      }

      // 5. Lọc theo Tần số cảm xúc
      if (emotion != null && emotion != 'all' && emotion!.isNotEmpty) {
        if (!u.emotion.toLowerCase().contains(emotion!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
