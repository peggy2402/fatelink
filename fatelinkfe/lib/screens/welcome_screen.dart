import 'package:flutter/material.dart';
import 'dart:ui';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Nền trắng ấm mờ
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8), // Frosted white canvas
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Cửa sổ hình hữu cơ (Egg-shape) chứa Faye AI ---
                  Container(
                    width: 200,
                    height: 260,
                    decoration: BoxDecoration(
                      // Tạo hình quả trứng (Elliptical)
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(100, 130),
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFFB87333,
                        ).withOpacity(0.5), // Viền màu đồng
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/avt_faye_ai.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4513).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Các quả cầu nhỏ trôi nổi
                        Positioned(
                          top: 40,
                          right: 40,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        Positioned(
                          bottom: 60,
                          left: 50,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Tag trạng thái Faye AI ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2723).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), // Chấm xanh lá
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Faye AI đang trực tuyến',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // --- Typography ---
                  const Text(
                    'Chúng ta cần',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723), // Nâu đậm
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'trao đổi để gặp gỡ đúng người hơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                          'serif', // Dùng serif in nghiêng thay cho script nếu chưa có font script
                      fontStyle: FontStyle.italic,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5D4037),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Khám phá những kết nối sâu sắc do Faye tinh tuyển, mang lại cảm giác chân thực như thể đã được định sẵn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF757575), // Xám trung tính
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- CTA Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFA0522D,
                        ), // Màu nâu đỏ sienna/terracotta
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: const Color(0xFFA0522D).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Chuyển sang màn hình Chat thực tế với Faye
                      },
                      child: const Text(
                        'Bắt đầu trò chuyện',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Liên kết phụ ---
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Tìm hiểu thêm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8D6E63), // Nâu nhạt
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF8D6E63),
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
