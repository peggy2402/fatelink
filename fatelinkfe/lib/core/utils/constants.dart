class AppConstants {
  // Thay đổi URL tại ĐÂY để áp dụng cho toàn bộ dự án
  static const String serverUrl = 'https://fatelink-be.fly.dev';
  // static const String serverUrl = 'http://127.0.0.1:3000'; // iOS Simulator / Web / Desktop
  // static const String serverUrl = 'http://192.168.0.213:3000'; // Dành cho iPhone thật trong cùng mạng WiFi

  // Nối sẵn /api để dùng cho các request HTTP thông thường
  static const String baseUrl = '$serverUrl/api';
  static const String apiVersion =
      'v1'; // Nếu có versioning, có thể thêm vào URL như: '$baseUrl/$apiVersion'
  // API Endpoints
  static const String loginWithGoogle = 'auth/google/login';
  static const String loginWithZalo = 'auth/zalo/login';
  static const String loginWithTikTok = 'auth/tiktok/login';
  static const String refreshToken = 'auth/refresh';
  static const String zaloAppId = '3205454775701109337';
  static const String logout = 'auth/logout';
  static const String userRecommendations = 'users/recommendations';

  static String userMatches(String userId) => 'users/$userId/matches';
  static String userProfile(String userId) => 'users/$userId/profile';
  static String sendMessage(String chatId) => 'chats/$chatId/messages';
  static String fetchMessages(String chatId) => 'chats/$chatId/messages';
  static String userFCMToken(String userId) => 'users/$userId/fcm-token';
  static String matchmakingRecommendations = 'matchmaking/recommendations';
  static const String updateFcmToken = 'users/fcm-token';
  static const String updateUserProfile = 'users/profile';
  static const String uploadImage = 'upload/image';
  static String userRecordView(String userId) => 'users/$userId/view';
  static String userToggleLike(String userId) => 'users/$userId/like';
  static String userRecordWave(String userId) => 'users/$userId/wave';
  static const String notifications = 'users/notifications';
  static String markNotificationRead(String id) => 'users/notifications/$id/read';
  static const String markAllNotificationsRead = 'users/notifications/read-all';

  // Điều khoản và dịch vụ, Chính sách v.v
  static const String childSafety = '/child-safety.html';
  static const String cookies = '/cookies.html';
  static const String privacyPolicy = '/privacy.html';
  static const String rules = '/rules.html';
  static const String support = '/support.html';
  static const String termsOfService = '/terms.html';
}
