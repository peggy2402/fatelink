import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../presentation/screens/match_chat_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/main_screen.dart';

class AppRouter {
  // Private constructor để ngăn việc khởi tạo object AppRouter()
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/match-chat':
        final args = settings.arguments;
        String partnerId = args is String ? args : 'unknown_id';
        return MaterialPageRoute(
          builder: (context) => MatchChatScreen(
            partnerId: partnerId,
            partnerName: 'FateLink'.tr(),
          ),
        );
      case '/onboarding':
        return MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        );
      case '/login':
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case '/main':
        return MaterialPageRoute(builder: (context) => const MainScreen());
      default:
        return null; // Trả về null để Flutter tự xử lý hoặc bạn có thể trả về một trang 404 (UnknownRouteScreen)
    }
  }
}
