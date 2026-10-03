import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/blocs/splash/splash_bloc.dart';
import '../../../logic/blocs/splash/splash_event.dart';
import '../../../logic/blocs/splash/splash_state.dart';
import '../login/login_screen.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _rippleController;
  late final AnimationController _breatheController;
  late final AnimationController _entranceController;
  late final AnimationController _waveController;

  // Staggered entrance animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _badgeSlide;
  late final Animation<double> _badgeFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _sloganFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    // 1. Radar wave pulse (vòng sóng cộng hưởng tần số vũ trụ)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Nhịp thở logo (organic breathing & float)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3. Staggered entrance timeline
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 4. Harmonic wave indicator animation (loading 3 chấm sóng)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Định nghĩa các đường cong xuất hiện phân tầng (Staggered Animations)
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _badgeSlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
      ),
    );

    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // Kích hoạt chuỗi animation mượt mà ngay khi mở
    _entranceController.forward();

    // Bắt đầu quy trình kiểm tra phiên đăng nhập của SplashBloc
    context.read<SplashBloc>().add(SplashStarted());
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _breatheController.dispose();
    _entranceController.dispose();
    _waveController.dispose();
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
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const OnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        } else if (state is SplashNavigateToLogin) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              settings: const RouteSettings(name: '/login'),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        } else if (state is SplashNavigateToHome) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              settings: const RouteSettings(name: '/main'),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainScreen(),
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // --- 1. Background Ethereal Cosmic Canvas ---
            const _CosmicBackgroundMesh(),

            // --- 2. Main Content Centered ---
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // --- Khung Logo Cosmic Resonance ---
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _breatheController,
                        _rippleController,
                      ]),
                      builder: (context, child) {
                        final breatheScale = 0.98 + (_breatheController.value * 0.05);
                        final totalScale = _logoScale.value * breatheScale;

                        return Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: totalScale,
                            child: child,
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Vòng tròn sóng lan tỏa radar 1
                          _RippleRing(
                            animation: _rippleController,
                            offset: 0.0,
                            size: 136,
                          ),
                          // Vòng tròn sóng lan tỏa radar 2
                          _RippleRing(
                            animation: _rippleController,
                            offset: 0.45,
                            size: 136,
                          ),

                          // Vầng hào quang nhạt phía sau (Radial Ambient Glow)
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 44,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 52,
                                  spreadRadius: 12,
                                ),
                              ],
                            ),
                          ),

                          // Khung kính mờ Glassmorphism bao bọc Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                width: 132,
                                height: 132,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  borderRadius: BorderRadius.circular(38),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.07),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFEC4899)
                                          .withValues(alpha: 0.16),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                // Thẻ 3D trắng sáng chứa biểu tượng chính thức của Meyu
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E)
                                            .withValues(alpha: 0.14),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/icon/app_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // --- Huy hiệu Badge: ✦ AI SOUL CONNECTION ✦ ---
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _badgeFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _badgeSlide.value),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEC4899).withValues(alpha: 0.08),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                              const Color(0xFF6366F1).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFEC4899),
                                  Color(0xFF8B5CF6),
                                ],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'AI SOUL CONNECTION',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- Tên Thương Hiệu MEYU với Gradient đa tầng ---
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlide.value),
                            child: child,
                          ),
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFF43F5E), // Rose Neon
                            Color(0xFFEC4899), // Pulse Pink
                            Color(0xFFA855F7), // Cosmic Violet
                            Color(0xFF6366F1), // Primary Indigo
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'MEYU',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- Slogan Kết Nối Trái Tim ---
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _sloganFade.value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'connectHeartsNoDistance'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // --- 3-Dot Harmonic Energy Wave Loader ---
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _loaderFade.value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: _CosmicFrequencyLoader(
                          controller: _waveController,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nền Cosmic đa tầng với các tinh vân mờ ảo tạo cảm giác vũ trụ huyền ảo
class _CosmicBackgroundMesh extends StatelessWidget {
  const _CosmicBackgroundMesh();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lớp nền Pearly White ngọc trai
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBF8FE),
                Color(0xFFFFFFFF),
                Color(0xFFF6F8FF),
              ],
            ),
          ),
        ),

        // Quầng sáng hồng trên bên trái (Pulse Pink)
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEC4899).withValues(alpha: 0.16),
            ),
          ),
        ),

        // Quầng sáng tím bên phải (Cosmic Violet)
        Positioned(
          top: 100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
            ),
          ),
        ),

        // Quầng sáng lam ở giữa (Cyan Accent)
        Positioned(
          top: 320,
          left: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            ),
          ),
        ),

        // Quầng sáng chàm dưới đáy (Primary Indigo)
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            ),
          ),
        ),

        // Lớp mờ khuếch tán diện rộng (Ultra-smooth Backdrop Blur)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }
}

/// Vòng sóng cộng hưởng radar lan tỏa
class _RippleRing extends StatelessWidget {
  final Animation<double> animation;
  final double offset;
  final double size;

  const _RippleRing({
    required this.animation,
    required this.offset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = (animation.value + offset) % 1.0;
        final scale = 1.0 + (progress * 0.75);
        final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.40;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEC4899).withValues(alpha: opacity),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: opacity * 0.5),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chỉ báo tải tần số sóng hài (Harmonic Wave Indicator)
class _CosmicFrequencyLoader extends StatelessWidget {
  final AnimationController controller;

  const _CosmicFrequencyLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0, const Color(0xFFEC4899)),
                const SizedBox(width: 8),
                _buildDot(1, const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _buildDot(2, const Color(0xFF6366F1)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Đang đồng bộ tần số...',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index, Color color) {
    final phase = (controller.value * 2 * math.pi) + (index * 0.7);
    final scale = 0.65 + (0.35 * (math.sin(phase) + 1) / 2);
    final opacity = 0.45 + (0.55 * (math.sin(phase) + 1) / 2);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
