import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';
import '../../logic/blocs/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '751936511912-tb3fd241um9i6d3h8u61bmk6tqbbs72p.apps.googleusercontent.com',
  );

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  bool _isTermsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Hiệu ứng "nảy" lặp lại cho nút đăng nhập chính
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản dịch vụ để tiếp tục.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Modal Sinh Trắc Học
  void _showBiometricPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Nền trong suốt để hiển thị hiệu ứng kính
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0514).withOpacity(0.7),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Đăng nhập sinh trắc học',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sử dụng khuôn mặt hoặc vân tay để đăng nhập an toàn mà không cần mật khẩu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBiometricOption(
                              Icons.face_retouching_natural,
                              'Face ID',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBiometricOption(
                              Icons.fingerprint,
                              'Touch ID',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBiometricOption(IconData icon, String title) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // TODO: Xử lý logic gọi hệ thống sinh trắc học
      },
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ), // Đổi sang neon/trắng
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0A0514,
      ), // Dark deep space color (#0a0514)
      body: Stack(
        children: [
          // --- Smooth Glowing Animated Mesh Gradient Background ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x668A2BE2), // Neon purple
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x66FF69B4), // Soft pink
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x664169E1), // Deep blue
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // --- Main Content ---
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else if (state is AuthAuthenticated) {
                // Đăng nhập thành công -> Văng vào trang chủ
                Navigator.pushReplacementNamed(context, '/main');
              }
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 80,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- Header ---
                          Column(
                            children: [
                              const SizedBox(height: 40),
                              // Glowing 3D heart icon inside a glassmorphic container
                              ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 20,
                                    sigmaY: 20,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF69B4,
                                          ).withOpacity(0.2),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => AppColors
                                          .primaryGradient
                                          .createShader(bounds),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'FateLink',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Bắt đầu tìm kiếm một nửa của bạn',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 60),

                          // --- Các nút Đăng Nhập ---
                          Column(
                            children: [
                              // Khu vực nút bấm chính (Primary Row)
                              Row(
                                children: [
                                  Expanded(
                                    child: BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) {
                                        final isLoading = state is AuthLoading;
                                        return ScaleTransition(
                                          scale: _bounceAnimation,
                                          child: ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : _handleGoogleSignIn,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black87,
                                              elevation: 10, // Soft drop shadow
                                              shadowColor: Colors.black
                                                  .withOpacity(0.4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 18,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                              ),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/icon-google.png',
                                                        width: 24,
                                                        height: 24,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Tiếp tục với Google',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nút Sinh Trắc Học
                                  InkWell(
                                    onTap: _showBiometricPopup,
                                    borderRadius: BorderRadius.circular(16),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.fingerprint,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'HOẶC ĐĂNG NHẬP BẰNG',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Các nút mạng xã hội khác (Secondary Row)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(
                                    'assets/icon/icon-facebook.png',
                                  ),
                                  const SizedBox(width: 24),
                                  _buildSocialButton(
                                    'assets/icon/icon-tiktok.png',
                                  ),
                                  const SizedBox(width: 24),
                                  _buildSocialButton(
                                    'assets/icon/icon-zalo.png',
                                  ),
                                  const SizedBox(width: 24),
                                  _buildSocialButton(
                                    'assets/icon/icon-phone.png',
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // --- Footer: Điều khoản ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => setState(
                                  () => _isTermsAccepted = !_isTermsAccepted,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment
                                      .center, // Thêm khoảng cách với text
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isTermsAccepted
                                          ? AppColors.primary
                                          : Colors.grey.shade600,
                                      width: 2,
                                    ),
                                    color: _isTermsAccepted
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                  child: _isTermsAccepted
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Tôi đã đọc và đồng ý với ',
                                      ),
                                      TextSpan(
                                        text: 'Điều khoản Dịch vụ',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri.parse(
                                              '${AppConstants.serverUrl}${AppConstants.termsOfService}',
                                            ),
                                          ),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Chính sách Quyền Riêng tư',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri.parse(
                                              '${AppConstants.serverUrl}${AppConstants.privacyPolicy}',
                                            ),
                                          ),
                                      ),
                                      TextSpan(
                                        text: ' & Chính sách Cookies',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri.parse(
                                              '${AppConstants.serverUrl}${AppConstants.cookies}',
                                            ),
                                          ),
                                      ),
                                      TextSpan(
                                        text: ' & Quy tắc của nền tảng',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri.parse(
                                              '${AppConstants.serverUrl}${AppConstants.rules}',
                                            ),
                                          ),
                                      ),
                                      TextSpan(
                                        text: ' & Quy định An toàn trẻ em.',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri.parse(
                                              '${AppConstants.serverUrl}${AppConstants.childSafety}',
                                            ),
                                          ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String assetPath) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
