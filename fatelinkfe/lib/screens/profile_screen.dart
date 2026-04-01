import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/screens/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarUrl;
  // Dữ liệu giả cho biểu đồ Radar
  final Map<String, double> emotionData = {
    'Stress': 4,
    'Lonely': 2,
    'Sadness': 3,
    'Calm': 8,
    'Warmth': 7,
    'Happy': 6,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      return data['sub'] ?? data['id'] ?? data['userId'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadUserProfile() async {
    const secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'accessToken');
    final avatar = await secureStorage.read(key: 'avatarUrl');

    if (mounted) {
      setState(() => _avatarUrl = avatar);
    }

    if (token == null) return;
    final userId = _getUserIdFromToken(token);
    if (userId == null) return;

    try {
      final url = Uri.parse(
        'https://fatelink-production.up.railway.app/users/$userId/profile',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['emotions'] != null) {
          setState(() {
            emotionData['Stress'] = (data['emotions']['stress'] ?? 5)
                .toDouble();
            emotionData['Lonely'] = (data['emotions']['loneliness'] ?? 5)
                .toDouble();
            emotionData['Sadness'] = (data['emotions']['sadness'] ?? 5)
                .toDouble();
            emotionData['Calm'] = (data['emotions']['calmness'] ?? 5)
                .toDouble();
            emotionData['Warmth'] = (data['emotions']['warmth'] ?? 5)
                .toDouble();
            emotionData['Happy'] = (data['emotions']['happiness'] ?? 5)
                .toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải profile: $e');
    }
  }

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

                const SizedBox(height: 24),

                // Biểu đồ Radar
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: emotionData.entries
                                .map((e) => RadarEntry(value: e.value))
                                .toList(),
                            borderColor: Colors.lightBlueAccent,
                            fillColor: Colors.lightBlueAccent.withOpacity(0.3),
                          ),
                        ],
                        getTitle: (index, angle) {
                          return RadarChartTitle(
                            text: emotionData.keys.elementAt(index),
                            angle: angle,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Card Cài đặt
                Expanded(
                  child: Container(
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          32,
                          24,
                          100,
                        ), // Padding bottom lớn để không vướng thanh Nav
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
                            Icons.settings_outlined,
                            'Cài đặt ứng dụng',
                            () {},
                          ),
                          _buildMenuButton(
                            Icons.language,
                            'Ngôn ngữ',
                            () {}, // TODO: Sẽ tích hợp thư viện đa ngôn ngữ vào đây
                          ),
                          _buildMenuButton(
                            Icons.privacy_tip_outlined,
                            'Quyền riêng tư & Điều khoản',
                            () {},
                          ),
                          const SizedBox(height: 24),

                          // Nút Đăng xuất
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(
                                  0.1,
                                ), // Nền đỏ mờ
                                foregroundColor: Colors.redAccent, // Chữ đỏ
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.redAccent.withOpacity(0.5),
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
                        ],
                      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.3),
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.withOpacity(0.5),
        child: const Icon(Icons.person, color: Colors.white, size: 60),
      ),
    );
  }
}
