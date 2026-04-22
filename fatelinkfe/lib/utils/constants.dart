class AppConstants {
  // Thay đổi URL tại ĐÂY để áp dụng cho toàn bộ dự án
  static const String serverUrl = 'https://fatelink-be.fly.dev';

  // Nối sẵn /api để dùng cho các request HTTP thông thường
  static const String baseUrl = '$serverUrl/api';

  // API Endpoints
  static const String loginWithGoogle = 'auth/google/login';
  static const String support = 'support';
  static const String userRecommendations = 'users/recommendations';

  static String userMatches(String userId) => 'users/$userId/matches';
  static String userProfile(String userId) => 'users/$userId/profile';
}
