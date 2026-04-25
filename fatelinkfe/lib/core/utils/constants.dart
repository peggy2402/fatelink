class AppConstants {
  // Thay đổi URL tại ĐÂY để áp dụng cho toàn bộ dự án
  static const String serverUrl = 'https://fatelink-be.fly.dev';

  // Nối sẵn /api để dùng cho các request HTTP thông thường
  static const String baseUrl = '$serverUrl/api';

  // API Endpoints
  static const String loginWithGoogle = 'auth/google/login';
  static const String userRecommendations = 'users/recommendations';

  static String userMatches(String userId) => 'users/$userId/matches';
  static String userProfile(String userId) => 'users/$userId/profile';
  static String sendMessage(String chatId) => 'chats/$chatId/messages';
  static String fetchMessages(String chatId) => 'chats/$chatId/messages';
  static String userFCMToken(String userId) => 'users/$userId/fcm-token';
  static const String updateFcmToken = 'users/fcm-token';

  // Điều khoản và dịch vụ, Chính sách v.v
  static const String childSafety = '/child-safety.html';
  static const String cookies = '/cookies.html';
  static const String privacyPolicy = '/privacy.html';
  static const String rules = '/rules.html';
  static const String support = '/support.html';
  static const String termsOfService = '/terms.html';
}
