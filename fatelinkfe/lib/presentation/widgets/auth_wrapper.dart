import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    // Yêu cầu BLoC kiểm tra token ngay khi App vừa khởi động
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainScreen(); // Đã có Token -> Vào app
        } else if (state is AuthUnauthenticated) {
          return const LoginScreen(); // Chưa có Token -> Đăng nhập
        }
        // Đang check Token hoặc Initial -> Hiển thị Splash Cinematic của bạn
        return const SplashScreen();
      },
    );
  }
}
