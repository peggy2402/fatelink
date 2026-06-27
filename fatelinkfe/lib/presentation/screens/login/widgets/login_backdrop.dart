import 'dart:ui';

import 'package:flutter/material.dart';

class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x30FFB2CF),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x22FFC7DB),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: const SizedBox(),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  left: -24,
                  right: -24,
                  bottom: 38,
                  child: ClipPath(
                    clipper: const _BackWaveClipper(),
                    child: Container(
                      height: 76,
                      color: const Color(0x38F9E7EF),
                    ),
                  ),
                ),
                Positioned(
                  left: -18,
                  right: -18,
                  bottom: 16,
                  child: ClipPath(
                    clipper: const _MainWaveClipper(),
                    child: Container(
                      height: 84,
                      color: const Color(0x52F7BCD4),
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  right: -10,
                  bottom: 0,
                  child: ClipPath(
                    clipper: const _FrontWaveClipper(),
                    child: Container(
                      height: 70,
                      color: const Color(0x70F7C6DA),
                    ),
                  ),
                ),
                const Positioned(
                  right: 30,
                  bottom: 42,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 34,
                    color: Color(0x99F3A0BF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackWaveClipper extends CustomClipper<Path> {
  const _BackWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.02,
        size.width * 0.22,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.46,
        size.width * 0.52,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.12,
        size.width * 0.78,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.26,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MainWaveClipper extends CustomClipper<Path> {
  const _MainWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.06,
        size.width * 0.24,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.58,
        size.width * 0.56,
        size.height * 0.40,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.24,
        size.width * 0.82,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.34,
        size.width,
        size.height * 0.56,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FrontWaveClipper extends CustomClipper<Path> {
  const _FrontWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.22,
        size.width * 0.26,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.66,
        size.width * 0.58,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.38,
        size.width * 0.84,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.50,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
