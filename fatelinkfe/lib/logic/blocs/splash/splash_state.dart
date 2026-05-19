abstract class SplashState {}

class SplashInitial extends SplashState {}

/// Trạng thái tải (đang chạy animation và check token)
class SplashLoading extends SplashState {}

class SplashNavigateToLogin extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashNavigateToOnboarding extends SplashState {}