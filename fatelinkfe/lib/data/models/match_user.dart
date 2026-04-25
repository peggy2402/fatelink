class MatchUser {
  final String id;
  final String name;
  final String emotion;
  final int compatibilityScore;

  MatchUser({
    required this.id,
    required this.name,
    required this.emotion,
    required this.compatibilityScore,
  });

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['displayName'] ?? json['name'] ?? 'Fater',
      emotion: json['dominantEmotion'] ?? json['detected_emotion'] ?? 'Bí ẩn',
      compatibilityScore:
          json['matchingScore'] ?? json['compatibilityScore'] ?? 80,
    );
  }
}
