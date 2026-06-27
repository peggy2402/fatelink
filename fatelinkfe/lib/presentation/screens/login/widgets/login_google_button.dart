import 'package:flutter/material.dart';

class LoginGoogleButton extends StatefulWidget {
  const LoginGoogleButton({
    super.key,
    required this.isLoading,
    required this.bounceAnimation,
    required this.onPressed,
  });

  final bool isLoading;
  final Animation<double> bounceAnimation;
  final VoidCallback onPressed;

  @override
  State<LoginGoogleButton> createState() => _LoginGoogleButtonState();
}

class _LoginGoogleButtonState extends State<LoginGoogleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.bounceAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isLoading) {
            setState(() => _isPressed = true);
          }
        },
        onTapCancel: () {
          if (!widget.isLoading) {
            setState(() => _isPressed = false);
          }
        },
        onTapUp: (_) {
          if (!widget.isLoading) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: _isPressed
                    ? const Color(0xFFA92264)
                    : const Color(0xFFD1D5DB),
                width: _isPressed ? 1.6 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isPressed ? 0.16 : 0.11,
                  ),
                  blurRadius: _isPressed ? 18 : 14,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: const Color(
                    0xFFA92264,
                  ).withValues(alpha: _isPressed ? 0.18 : 0.08),
                  blurRadius: _isPressed ? 22 : 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F2741),
                disabledBackgroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFA92264),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/icon-google.png',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 14),
                        const Flexible(
                          child: Text(
                            'Tiếp tục với Google',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
