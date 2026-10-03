import 'dart:convert';

/// Thời hạn lưu trữ tự động của bức ảnh trong Góc tâm hồn (Vibes)
enum VibeDurationOption {
  fifteenMinutes(15, '15 phút', '⏱️', 'Khoảnh khắc thoáng qua'),
  oneHour(60, '1 giờ', '⏳', 'Tâm trạng tức thời'),
  eightHours(480, '8 giờ', '🌙', 'Một giấc ngủ / Một buổi làm'),
  twentyFourHours(1440, '24 giờ', '☀️', 'Một ngày định mệnh (Khuyên dùng)'),
  sevenDays(10080, '7 ngày', '🗓️', 'Một tuần cảm xúc'),
  thirtyDays(43200, '30 ngày', '🪐', 'Một chu kỳ trăng (Tối đa)');

  final int minutes;
  final String label;
  final String icon;
  final String description;

  const VibeDurationOption(this.minutes, this.label, this.icon, this.description);

  Duration get duration => Duration(minutes: minutes);

  static VibeDurationOption fromMinutes(int minutes) {
    for (final opt in VibeDurationOption.values) {
      if (opt.minutes == minutes) return opt;
    }
    return VibeDurationOption.twentyFourHours;
  }
}

/// Đối tượng ảnh Góc tâm hồn có cơ chế tự động xóa (Ephemeral Photo)
class VibePhotoItem {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final int durationMinutes;
  final DateTime expiresAt;

  VibePhotoItem({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.durationMinutes,
    required this.expiresAt,
  });

  /// Tạo một VibePhotoItem mới với tùy chọn thời lượng
  factory VibePhotoItem.createNew({
    required String imageUrl,
    VibeDurationOption option = VibeDurationOption.twentyFourHours,
  }) {
    final now = DateTime.now();
    return VibePhotoItem(
      id: 'vibe_${now.millisecondsSinceEpoch}_${imageUrl.hashCode.abs()}',
      imageUrl: imageUrl,
      createdAt: now,
      durationMinutes: option.minutes,
      expiresAt: now.add(option.duration),
    );
  }

  /// Kiểm tra ảnh đã hết hạn chưa
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Thời gian còn lại dạng chuỗi thân thiện
  String get remainingTimeFormatted {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Hết hạn';
    final diff = expiresAt.difference(now);

    if (diff.inDays >= 1) {
      final hours = diff.inHours % 24;
      return hours > 0 ? '${diff.inDays}d ${hours}h' : '${diff.inDays} ngày';
    }
    if (diff.inHours >= 1) {
      final mins = diff.inMinutes % 60;
      return mins > 0 ? '${diff.inHours}h ${mins}p' : '${diff.inHours} giờ';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút';
    }
    return '< 1 phút';
  }

  /// Nhãn hiển thị tổng thời gian
  String get durationLabel {
    final opt = VibeDurationOption.fromMinutes(durationMinutes);
    return opt.label;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory VibePhotoItem.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now();
    final dur = json['durationMinutes'] as int? ?? 1440;
    final expires = json['expiresAt'] != null
        ? DateTime.tryParse(json['expiresAt'] as String) ?? created.add(Duration(minutes: dur))
        : created.add(Duration(minutes: dur));

    return VibePhotoItem(
      id: json['id'] as String? ?? 'vibe_${created.millisecondsSinceEpoch}',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: created,
      durationMinutes: dur,
      expiresAt: expires,
    );
  }

  /// Tương thích ngược: Nếu dữ liệu trong prefs là chuỗi URL hoặc base64 thuần
  factory VibePhotoItem.fromRaw(String raw) {
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        return VibePhotoItem.fromJson(decoded);
      } catch (_) {
        // Fallback sang parse raw bên dưới
      }
    }

    // Bản ghi cũ chưa có thông tin thời hạn -> Gán mặc định 7 ngày kể từ hiện tại
    final now = DateTime.now();
    return VibePhotoItem(
      id: 'legacy_${raw.hashCode.abs()}',
      imageUrl: raw,
      createdAt: now,
      durationMinutes: 10080, // 7 ngày
      expiresAt: now.add(const Duration(days: 7)),
    );
  }

  /// Serialize thành JSON String để lưu vào SharedPreferences StringList
  String toRawString() {
    return jsonEncode(toJson());
  }

  /// Lọc và loại bỏ các ảnh đã hết hạn
  static List<VibePhotoItem> filterActive(List<VibePhotoItem> items) {
    return items.where((item) => !item.isExpired && item.imageUrl.isNotEmpty).toList();
  }
}
