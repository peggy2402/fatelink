import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    // Đợi một chút để hiển thị splash screen cho đẹp
    await Future.delayed(const Duration(seconds: 2));

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
      backgroundColor: const Color(0xFF002B3D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/app_logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const Text(
              'FATELINK',
              style: TextStyle(
                color: Color(0xFFBD114A),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
