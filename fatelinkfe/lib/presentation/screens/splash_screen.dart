import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0514), // Dark deep space background
      body: Stack(
        children: [
          // --- Mesh Gradient Background ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x668A2BE2), // Neon purple blob
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
                color: Color(0x66FF69B4), // Soft pink blob
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // --- Foreground Content ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/icon/bounce_logo.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          20 * (1 - value),
                        ), // Trượt lên nhẹ nhàng
                        child: Text(
                          'FATELINK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38, // Tăng thêm chút xíu cho quyền lực
                            fontWeight: FontWeight.w900, // Cực đậm
                            letterSpacing: 8.0,
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFFFF69B4,
                                ).withOpacity(0.5), // Pink Glow
                                blurRadius: 20.0,
                              ),
                              Shadow(
                                color: const Color(
                                  0xFF8A2BE2,
                                ).withOpacity(0.3), // Purple Glow
                                blurRadius: 40.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
