import 'package:flutter/material.dart';

import '../../../../core/utils/toast_utils.dart';

class LoginSocialOptionsRow extends StatelessWidget {
  const LoginSocialOptionsRow({
    super.key,
    required this.isLoading,
    required this.isTikTokLoading,
    required this.isZaloLoading,
    required this.onTikTokSignIn,
    required this.onZaloSignIn,
    required this.onShowPhoneOtpSheet,
  });

  final bool isLoading;
  final bool isTikTokLoading;
  final bool isZaloLoading;
  final VoidCallback onTikTokSignIn;
  final VoidCallback onZaloSignIn;
  final VoidCallback onShowPhoneOtpSheet;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Facebook
        LoginSocialButton(
          label: 'Facebook',
          iconWidget: _buildFacebookBadge(),
          isDisabled: isLoading,
          onTap: () => ToastUtil.showInfo(
            context,
            'Facebook login trên app chưa được nối SDK.',
          ),
        ),

        // 2. TikTok
        LoginSocialButton(
          label: 'TikTok',
          iconWidget: _buildTikTokBadge(),
          isLoading: isTikTokLoading,
          isDisabled: isLoading && !isTikTokLoading,
          onTap: onTikTokSignIn,
        ),

        // 3. Zalo
        LoginSocialButton(
          label: 'Zalo',
          iconWidget: _buildZaloBadge(),
          isLoading: isZaloLoading,
          isDisabled: isLoading && !isZaloLoading,
          onTap: onZaloSignIn,
        ),

        // 4. Phone SMS OTP
        LoginSocialButton(
          label: 'SMS OTP',
          iconWidget: _buildPhoneBadge(),
          isDisabled: isLoading,
          onTap: onShowPhoneOtpSheet,
        ),
      ],
    );
  }

  static Widget _buildFacebookBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/icon-facebook.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static Widget _buildTikTokBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/icon-tiktok.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static Widget _buildZaloBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0068FF).withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _ZaloBubblePainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              'Zalo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPhoneBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.phone_iphone_rounded,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}

class LoginSocialButton extends StatefulWidget {
  const LoginSocialButton({
    super.key,
    required this.label,
    required this.iconWidget,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;

  @override
  State<LoginSocialButton> createState() => _LoginSocialButtonState();
}

class _LoginSocialButtonState extends State<LoginSocialButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = widget.isDisabled || widget.isLoading;

    return GestureDetector(
      onTapDown: effectiveDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: effectiveDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: effectiveDisabled ? null : () => setState(() => _isPressed = false),
      onTap: effectiveDisabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF1E5ED),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB4D1).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFFF43F5E),
                          ),
                        )
                      : Opacity(
                          opacity: widget.isDisabled ? 0.45 : 1.0,
                          child: widget.iconWidget,
                        ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZaloBubblePainter extends CustomPainter {
  const _ZaloBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0068FF), Color(0xFF0084FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = w * 0.42;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.94),
      Radius.circular(r),
    ));

    final tail = Path();
    tail.moveTo(w * 0.22, h * 0.82);
    tail.lineTo(w * 0.12, h * 1.0);
    tail.lineTo(w * 0.38, h * 0.92);
    tail.close();
    path.addPath(tail, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
