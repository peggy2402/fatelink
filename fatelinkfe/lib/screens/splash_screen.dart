import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:fatelinkfe/screens/login_screen.dart';
import 'package:fatelinkfe/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Tăng thời gian chờ để khớp với Lottie animation và typography effect
    await Future.delayed(const Duration(seconds: 3));

    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');

      if (!mounted) return;

      if (accessToken != null && accessToken.isNotEmpty) {
        // Nếu có token, chuyển đến màn hình Home
        // TODO: Thay thế bằng màn hình Home/Chat thực tế
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        // Nếu không có token, chuyển đến màn hình Login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Nếu có lỗi, vẫn chuyển đến màn hình Login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF002B3D), // Màu xanh biển sâu làm tâm điểm
              Color(0xFF00080D), // Đen tĩnh mịch và bí ẩn viền ngoài
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/icon/bounce_logo.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)), // Trượt lên nhẹ nhàng
                    child: Text(
                      'FATELINK',
                      style: TextStyle(
                        color: const Color(0xFFBD114A),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6.0,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFBD114A).withOpacity(0.6),
                            blurRadius: 15.0, // Hiệu ứng Glow sát chữ
                          ),
                          Shadow(
                            color: const Color(0xFFBD114A).withOpacity(0.3),
                            blurRadius: 30.0, // Hiệu ứng Glow lan toả
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
