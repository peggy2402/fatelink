import 'package:flutter/material.dart';
import 'login_support_modal.dart';

class LoginSupportButton extends StatelessWidget {
  const LoginSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LoginSupportModal.show(context),
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
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
                  size: 14,
                  color: Color(0xFFF43F5E),
                ),
                SizedBox(width: 4),
                Text(
                  'Hỗ trợ 24/7',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
  final double size;

  const LoginLogoMark({super.key, this.size = 104.0});

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
    final size = widget.size;
    final outerSize = size * 1.12;

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
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.36),
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
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.09),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                  blurRadius: size * 0.27,
                  offset: Offset(0, size * 0.09),
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
  final double fontSize;

  const LoginBrandTitle({super.key, this.fontSize = 42.0});

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
      child: Text(
        'Meyu',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class LoginSlogan extends StatelessWidget {
  final double fontSize;

  const LoginSlogan({super.key, this.fontSize = 13.5});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Đăng nhập để tiếp tục kết nối tần số trái tim',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF64748B),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );
  }
}
