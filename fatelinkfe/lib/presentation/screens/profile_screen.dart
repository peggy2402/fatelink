import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../logic/blocs/profile/profile_bloc.dart';
import '../../logic/blocs/profile/profile_event.dart';
import '../../logic/blocs/profile/profile_state.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showChartData = false;

  @override
  void initState() {
    super.initState();
    // Kích hoạt Event load data khi trang vừa được mở
    context.read<ProfileBloc>().add(LoadProfileEvent(context));
    
    // Kích hoạt hiệu ứng bung to (Animation) sau khi UI xuất hiện 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showChartData = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Để lộ nền background từ MainScreen
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD114A)),
            );
          }

          if (state is ProfileError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is ProfileLoaded) {
            // Dữ liệu đã được bóc tách sẵn từ ProfileBloc
            final data = state.profileData;
            print('========== DEBUG Profile Data ==========');
            print('Raw Profile Data: $data');
            print('Field Name: ${data['name']}');
            print('=======================================');
            // Lấy object 'emotions' từ Backend trả về, fallback bằng map mặc định nếu rỗng
            final emotions =
                data['emotions'] ??
                {
                  'stress': 0.4,
                  'lonely': 0.3,
                  'sadness': 0.2,
                  'calm': 0.8,
                  'warmth': 0.7,
                  'happy': 0.6,
                };

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBD114A).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          // Kiểm tra chuỗi rỗng ngoài việc check null
                          (data['avatar'] != null && data['avatar'].toString().isNotEmpty)
                              ? data['avatar']
                              : ((data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
                                  ? data['avatarUrl']
                                  : 'https://ui-avatars.com/api/?name=${data['name'] ?? 'User'}&background=random&format=png'),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Bắt lỗi âm thầm nếu tải ảnh thất bại và thay bằng Icon mặc định
                            debugPrint('⚠️ Lỗi tải avatar: \$error');
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.white.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      (data['name'] != null && data['name'].toString().trim().isNotEmpty)
                          ? data['name']
                          : 'User'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tiêu đề biểu đồ
                    Text(
                      'emotion_frequency'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontFamily: 'serif',
                      ),
                    ),

                    // Biểu đồ Radar Chart
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: _buildRadarChart(emotions),
                    ),

                    const SizedBox(height: 40),
                    // Nút Đăng xuất
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: Text('Logout'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Hàm cấu hình cấu trúc biểu đồ Radar của fl_chart
  Widget _buildRadarChart(Map<String, dynamic> emotions) {
    // Parse các giá trị double để an toàn tránh Crash
    final double stress = (emotions['stress'] ?? 0).toDouble();
    final double lonely = (emotions['lonely'] ?? 0).toDouble();
    final double sadness = (emotions['sadness'] ?? 0).toDouble();
    final double calm = (emotions['calm'] ?? 0).toDouble();
    final double warmth = (emotions['warmth'] ?? 0).toDouble();
    final double happy = (emotions['happy'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: RadarChart(
        RadarChartData(
          tickCount: 4, // Số vòng lưới
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
          ), // Ẩn số liệu độ đo
          gridBorderData: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ), // Lưới nhện
          tickBorderData: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ), // Đường thẳng chia lưới
          titlePositionPercentageOffset: 0.15, // Khoảng cách chữ so với viền
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return RadarChartTitle(text: 'stress'.tr(), angle: angle);
              case 1:
                return RadarChartTitle(text: 'loneliness'.tr(), angle: angle);
              case 2:
                return RadarChartTitle(text: 'sadness'.tr(), angle: angle);
              case 3:
                return RadarChartTitle(text: 'calmness'.tr(), angle: angle);
              case 4:
                return RadarChartTitle(text: 'warmth'.tr(), angle: angle);
              case 5:
                return RadarChartTitle(text: 'happiness'.tr(), angle: angle);
              default:
                return const RadarChartTitle(text: '');
            }
          },
          titleTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          dataSets: [
            RadarDataSet(
              fillColor: const Color(
                0xFFBD114A,
              ).withOpacity(0.4), // Màu fill bên trong
              borderColor: const Color(0xFFBD114A), // Màu đường viền Radar
              entryRadius: 4, // Kích thước chấm tròn tại mỗi đỉnh
              dataEntries: [
                RadarEntry(value: _showChartData ? stress : 0),
                RadarEntry(value: _showChartData ? lonely : 0),
                RadarEntry(value: _showChartData ? sadness : 0),
                RadarEntry(value: _showChartData ? calm : 0),
                RadarEntry(value: _showChartData ? warmth : 0),
                RadarEntry(value: _showChartData ? happy : 0),
              ],
            ),
          ],
        ),
        swapAnimationDuration: const Duration(
          milliseconds: 800,
        ), // Hiệu ứng mượt khi update data
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }
}
