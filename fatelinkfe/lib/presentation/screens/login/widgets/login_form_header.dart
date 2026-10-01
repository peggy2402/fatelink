import 'package:flutter/material.dart';
import 'login_support_modal.dart';

class LoginSupportButton extends StatelessWidget {
  const LoginSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LoginSupportModal.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.headset_mic_rounded,
                  size: 16,
                  color: Color(0xFFF43F5E),
                ),
                SizedBox(width: 6),
                Text(
                  'Hỗ trợ 24/7',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF43F5E),
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

class LoginLogoMark extends StatefulWidget {
  const LoginLogoMark({super.key});

  @override
  State<LoginLogoMark> createState() => _LoginLogoMarkState();
}

class _LoginLogoMarkState extends State<LoginLogoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Outer Pulse Ring
          AnimatedBuilder(
            animation: _pulseScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF43F5E).withValues(alpha: 0.25),
                        const Color(0xFFA855F7).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main 3D Card Squircle
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icon/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginBrandTitle extends StatelessWidget {
  const LoginBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Color(0xFFF43F5E), // Rose
            Color(0xFFA855F7), // Purple
            Color(0xFF6366F1), // Indigo
          ],
        ).createShader(bounds);
      },
      child: const Text(
        'Meyu',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 44,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class LoginSlogan extends StatelessWidget {
  const LoginSlogan({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Đăng nhập để tiếp tục kết nối tần số trái tim',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
