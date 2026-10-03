import 'dart:math' as math;

class MatchUser {
  final String id;
  final String name;
  final String emotion;
  final int compatibilityScore;
  final double? distanceKm;
  final List<String>? tags;
  final String? avatar;
  final String? moodIcon;
  final bool isFaceLocked;
  final bool isMutualFollow;
  final bool isLiked;
  final List<String>? vibePhotos;
  final String? bio;
  final String? gender;
  final int? age;
  final int? likesCount;

  MatchUser({
    required this.id,
    required this.name,
    required this.emotion,
    required this.compatibilityScore,
    this.distanceKm,
    this.tags,
    this.avatar,
    this.moodIcon,
    this.isFaceLocked = false,
    this.isMutualFollow = false,
    this.isLiked = false,
    this.vibePhotos,
    this.bio,
    this.gender,
    this.age,
    this.likesCount,
  });

  MatchUser copyWith({
    String? id,
    String? name,
    String? emotion,
    int? compatibilityScore,
    double? distanceKm,
    List<String>? tags,
    String? avatar,
    String? moodIcon,
    bool? isFaceLocked,
    bool? isMutualFollow,
    bool? isLiked,
    List<String>? vibePhotos,
    String? bio,
    String? gender,
    int? age,
    int? likesCount,
  }) {
    return MatchUser(
      id: id ?? this.id,
      name: name ?? this.name,
      emotion: emotion ?? this.emotion,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      distanceKm: distanceKm ?? this.distanceKm,
      tags: tags ?? this.tags,
      avatar: avatar ?? this.avatar,
      moodIcon: moodIcon ?? this.moodIcon,
      isFaceLocked: isFaceLocked ?? this.isFaceLocked,
      isMutualFollow: isMutualFollow ?? this.isMutualFollow,
      isLiked: isLiked ?? this.isLiked,
      vibePhotos: vibePhotos ?? this.vibePhotos,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  /// Điều kiện mở diện mạo thật: cả hai cùng thả tim (mutual follow) VÀ đối phương không bật khóa diện mạo
  bool get canViewIdentity => isMutualFollow && !isFaceLocked;

  /// Mã định danh tâm hồn ngắn gọn (4 ký tự cuối của id viết hoa)
  String get soulId => id.isNotEmpty && id.length >= 4
      ? id.substring(id.length - 4).toUpperCase()
      : (id.isNotEmpty ? id.toUpperCase() : 'SOUL');

  /// Bí danh ngẫu nhiên chuẩn (vd: Soul#31241, Nova#8A49C)
  /// Sử dụng seed từ id để mỗi người có bí danh ngẫu nhiên nhưng cố định (deterministic),
  /// không bị thay đổi loạn xạ mỗi khi widget rebuild hoặc refresh
  String get anonymousName {
    final seed = id.isNotEmpty ? id.hashCode : 42;
    final rng = math.Random(seed);

    const prefixes = [
      'Soul',
      'Nova',
      'Aura',
      'Echo',
      'Cosmo',
      'Vibe',
      'Mystic',
      'Astral',
      'Luna',
      'Pulse',
    ];
    final prefix = prefixes[rng.nextInt(prefixes.length)];

    // Sinh chuỗi 5 ký tự ngẫu nhiên bao gồm cả chữ và số (ví dụ: 31241, 9X48B)
    const chars = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final code = List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();

    return '$prefix#$code';
  }

  /// Tên hiển thị chuẩn: nếu chưa mở diện mạo thì là bí danh ngẫu nhiên (vd: Soul#31241, Nova#8A49C)
  String get displayName => canViewIdentity ? name : anonymousName;

  /// Độ tuổi cố định theo seed hoặc từ dữ liệu profile
  int get resolvedAge {
    if (age != null && age! > 0) return age!;
    final seed = id.isNotEmpty ? id.hashCode : 42;
    return 19 + (seed.abs() % 14); // 19 - 32 tuổi
  }

  /// Giới tính chuẩn hóa ('female', 'male')
  String get resolvedGender {
    if (gender != null && gender!.isNotEmpty) {
      final g = gender!.toLowerCase().trim();
      if (g == 'female' || g == 'nữ' || g == 'nu' || g == 'f') return 'female';
      if (g == 'male' || g == 'nam' || g == 'm') return 'male';
      return g;
    }
    final seed = id.isNotEmpty ? id.hashCode : 42;
    return (seed.abs() % 2 == 0) ? 'female' : 'male';
  }

  /// Nhãn hiển thị tiếng Việt cho giới tính
  String get genderLabel {
    switch (resolvedGender) {
      case 'female':
        return 'Nữ';
      case 'male':
        return 'Nam';
      default:
        return 'Khác';
    }
  }

  /// Số lượt tim nhận được từ dữ liệu thực tế Database (loại bỏ hoàn toàn mock random)
  int get resolvedLikesCount => likesCount ?? 0;

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['displayName'] ?? json['name'] ?? 'Fater',
      emotion: json['dominantEmotion'] ?? json['detected_emotion'] ?? 'Bí ẩn',
      compatibilityScore:
          json['matchingScore'] ?? json['compatibilityScore'] ?? 80,
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : null,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      avatar: json['avatar'] as String?,
      moodIcon: json['moodIcon'] as String?,
      isFaceLocked: json['isFaceLocked'] == true,
      isMutualFollow: json['isMutualFollow'] == true || json['isMatched'] == true,
      isLiked: json['isLiked'] == true,
      vibePhotos: (json['vibePhotos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] != null
          ? (json['age'] as num).toInt()
          : (json['birthYear'] != null
              ? (DateTime.now().year - (json['birthYear'] as num).toInt())
              : null),
      likesCount: json['likesReceived'] != null
          ? (json['likesReceived'] as num).toInt()
          : (json['likesCount'] != null
              ? (json['likesCount'] as num).toInt()
              : (json['heartCount'] != null
                  ? (json['heartCount'] as num).toInt()
                  : 0)),
    );
  }
}
