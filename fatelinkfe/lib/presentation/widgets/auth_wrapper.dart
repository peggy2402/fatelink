import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_state.dart';
import '../../logic/blocs/auth/auth_event.dart';

// Import các màn hình của bạn
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart'; // Đảm bảo bạn có import đúng
import '../screens/main_screen.dart'; // Đảm bảo bạn có import đúng

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    // 1. Đợi 3 giây cho Lottie Animation của Splash Screen chạy xong
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 2. Đọc trạng thái xem có phải lần đầu tiên mở app không
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      // Lần đầu tiên -> Chuyển đến Onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      // Đã qua Onboarding -> Yêu cầu BLoC kiểm tra token để vào Main hoặc Login
      context.read<AuthBloc>().add(AuthCheckRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Lắng nghe kết quả từ AuthCheckRequested
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/main');
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      // Luôn hiển thị giao diện Splash Screen gốc trong 3s đầu và lúc BLoC đang loading
      child: const SplashScreen(),
    );
  }
}
