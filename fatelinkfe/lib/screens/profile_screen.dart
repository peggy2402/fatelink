import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'accessToken');

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Xóa toàn bộ stack màn hình trước đó
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      body: Stack(
        children: [
          // --- Nền Mesh Gradient ---
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0066FF), // Đổi blob đỏ thành xanh dương
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: const SizedBox(),
            ),
          ),

          // --- Nội dung Profile ---
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Hồ Sơ Của Bạn',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Avatar Glassmorphism
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ), // Viền trắng
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2), // Glow trắng
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/avt_faye_ai.png',
                      ), // Placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Người Dùng FateLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tần số: Đang cập nhật...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // Card Cài đặt
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMenuButton(
                          Icons.person_outline,
                          'Thông tin cá nhân',
                          () {},
                        ),
                        _buildMenuButton(
                          Icons.graphic_eq,
                          'Phân tích tần số',
                          () {},
                        ),
                        _buildMenuButton(
                          Icons.privacy_tip_outlined,
                          'Quyền riêng tư',
                          () {},
                        ),
                        const Spacer(),

                        // Nút Đăng xuất
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(
                                0.1,
                              ), // Nền mờ
                              foregroundColor: Colors.white, // Chữ trắng
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: () => _logout(context),
                            child: const Text(
                              'Đăng Xuất',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80), // Cách đáy cho BottomNavBar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white38,
        size: 16,
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
