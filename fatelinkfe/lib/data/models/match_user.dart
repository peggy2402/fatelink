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
  final List<String>? vibePhotos;
  final String? bio;

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
    this.vibePhotos,
    this.bio,
  });

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
      vibePhotos: (json['vibePhotos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      bio: json['bio'] as String?,
    );
  }
}
