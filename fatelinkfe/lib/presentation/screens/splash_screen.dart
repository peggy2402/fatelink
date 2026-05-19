import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/splash/splash_bloc.dart';
import '../../logic/blocs/splash/splash_event.dart';
import '../../logic/blocs/splash/splash_state.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _scaleAnimation;
  bool _showSlogan = false;

  @override
  void initState() {
    super.initState();

    // Animation nhịp tim
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    // Kích hoạt slogan hiện ra sau 0.8s
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showSlogan = true;
        });
      }
    });

    // Gửi sự kiện bắt đầu Splash để BLoC làm việc (đếm giờ & check token)
    context.read<SplashBloc>().add(SplashStarted());
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              settings: const RouteSettings(name: '/onboarding'),
              pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        } else if (state is SplashNavigateToLogin) {
          // Sử dụng FadeTransition thay vì hiệu ứng trượt mặc định của iOS
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              settings: const RouteSettings(name: '/login'),
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800), // Thời gian mờ 0.8s
            ),
            (route) => false, // Xoá sạch mọi route rác ở dưới
          );
        } else if (state is SplashNavigateToHome) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              settings: const RouteSettings(name: '/main'),
              pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // --- Nền LinearGradient mượt mà ---
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade50, // Pink 50
                const Color(0xFFFFF1F2), // Rose 50
                Colors.purple.shade100, // Purple 100
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // --- Khung Logo Glassmorphism ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn sáng mờ (Glowing Blur) nhấp nháy phía sau
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Khung kính mờ (Glassmorphism)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          // Squircle Gradient bên trong
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF69B4), Color(0xFFFF3B30)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Chữ FateLink Gradient ---
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    'FATELINK',
                    style: TextStyle(
                      color: Colors.white, // Bắt buộc phải là white để ShaderMask vẽ đè lên
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Slogan Fade In ---
                AnimatedOpacity(
                  opacity: _showSlogan ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  child: const Text(// "Destiny Connects" trong tiếng Việt
                     'Kết nối trái tim, không khoảng cách',
                    style: TextStyle(
                      color: Color(0xFF6B7280), // Xám thanh lịch
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // --- Loading Indicator tinh tế ---
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF69B4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
