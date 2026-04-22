import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '751936511912-tb3fd241um9i6d3h8u61bmk6tqbbs72p.apps.googleusercontent.com', // Uncomment và điền nếu cần cấu hình Web Client ID cho Android/iOS
  );

  Future<void> _handleGoogleSignIn() async {
    try {
      // Bắt đầu luồng đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng hủy (cancel) hộp thoại đăng nhập
        return;
      }

      // Lấy thông tin xác thực (chứa idToken)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        // Truyền idToken vào BLoC để gửi lên Backend
        if (mounted) {
          context.read<AuthBloc>().add(AuthLoginRequested(idToken));
        }
      } else {
        throw Exception('Không thể lấy được idToken từ Google.');
      }
    } catch (error) {
      debugPrint('Lỗi Google Sign-In: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thất bại, vui lòng thử lại!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520), // Dark theme
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Lắng nghe trạng thái Lỗi để hiển thị thông báo
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // UI Placeholder cho Logo
                const Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: Color(0xFFBD114A),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FateLink',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),

                // Lắng nghe state để vô hiệu hóa/hiển thị loading khi đang đăng nhập
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        isLoading ? 'Đang kết nối...' : 'Tiếp tục với Google',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
