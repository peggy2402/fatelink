import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FateLink',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // THAY ID NÀY: Bằng GOOGLE_CLIENT_ID của bạn (giống hệt trong file .env của backend)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '751936511912-66rq82kiakvl8o86i572io18gii7tahd.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // --- CONFIG: Đổi URL của backend tại đây ---
  // Môi trường thật (khi deploy lên Vercel): 'https://fatelink-be.vercel.app'
  // Môi trường test (máy ảo Android): 'http://10.0.2.2:3000'
  // Môi trường test (máy ảo iOS/Web): 'http://localhost:3000'
  static const String _baseUrl = 'http://10.0.2.2:3000';

  String _status = 'Chưa đăng nhập';

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _status = 'Đang mở Google Sign In...');

      // 1. Mở popup/màn hình đăng nhập Google của hệ điều hành
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _status = 'Đã hủy đăng nhập');
        return;
      }

      // 2. Lấy thông tin xác thực (chứa idToken)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        setState(() => _status = 'Đã lấy được Token!\nĐang gửi lên Backend...');

        // 3. Gửi Token lên Backend NestJS
        // LƯU Ý: Nếu bạn chạy bằng máy ảo Android (Emulator), phải dùng 10.0.2.2 thay vì localhost
        // Nếu chạy trên Web hoặc iOS Simulator, dùng localhost
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/google/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': idToken}),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          setState(
            () => _status =
                '✅ ĐĂNG NHẬP THÀNH CÔNG!\nBackend phản hồi:\n${response.body}',
          );
        } else {
          setState(() => _status = '❌ Lỗi Backend: Mã ${response.statusCode}');
        }
      } else {
        setState(() => _status = '❌ Không lấy được ID Token từ Google');
      }
    } catch (error) {
      setState(() => _status = '❌ Lỗi: $error');
      print('Chi tiết lỗi Google SignIn: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FateLink - Test Đăng Nhập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Tiếp tục với Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _handleGoogleSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
