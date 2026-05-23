import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import '../../logic/blocs/profile/profile_bloc.dart';
import '../../logic/blocs/profile/profile_event.dart';
import '../../logic/blocs/profile/profile_state.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';
import '../widgets/back.dart';
import '../../logic/blocs/main/main_bloc.dart';
import '../../logic/blocs/main/main_event.dart'; // Đảm bảo file này chứa event chuyển tab của bạn
import '../../presentation/widgets/menu.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: AppMenuDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFF3E8FF), // Tím nhạt
              Color(0xFFE0F2FE), // Xanh dương nhạt
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.6, 1.0],
          ),
        ),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
            }

            if (state is ProfileError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }

            if (state is ProfileLoaded) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSoulIdCard(),
                          const SizedBox(height: 24),
                          _buildLockedPhotoAlert(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 32),
                          _buildHobbiesSection(),
                          const SizedBox(height: 32),
                          _buildVibeCorner(),
                          const SizedBox(height: 32),
                          _buildPersonalityChart(),
                          const SizedBox(height: 40),
                          _buildLogoutButton(context),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.8),
      centerTitle: true,
      title: Text(
        'MyProfile'.tr(),
        style: TextStyle(
          color: Color(0xFF1E293B), // Slate-800
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: Center(
        child: CustomBackButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Gọi event lùi về Tab TRƯỚC ĐÓ trong lịch sử
              context.read<MainBloc>().add(PopTabEvent()); 
            }
          },
        ),
      ),
      actions: [
        _buildAppBarIcon(Icons.menu_rounded),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildAppBarIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: const Color(0xFF1E293B), size: 22),
        ),
      ),
    );
  }

  // A. Thẻ Soul ID Card (Điểm nhấn lớn nhất)
  Widget _buildSoulIdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.05), // Bóng màu tím nhạt
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần Trên: Avatar & Thông tin
          Row(
            children: [
              // Avatar Squircle
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        'https://api.dicebear.com/7.x/adventurer/png?seed=Luna&backgroundColor=f3e8ff',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC084FC), Color(0xFF4F46E5)], // Purple to Indigo
                        ),
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Thông tin (Phải)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mưa Đêm',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2), // Rose-50
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '♀ 22',
                            style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ID: #8821_SOUL',
                      style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), // Slate-100
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 6),
                          Text(
                            'Đang chênh vênh...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          // Phần Dưới: Bio & Vị trí
          const Text(
            '"Trời đổ mưa rồi, tự nhiên thấy lòng trống rỗng. Cần một người cùng im lặng nghe nhạc qua đêm nay..."',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF94A3B8)),
              SizedBox(width: 6),
              Text(
                'Lẩn trốn tại Hà Nội',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // B. Box Khóa Ảnh (Tính năng ẩn danh)
  Widget _buildLockedPhotoAlert() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFF4F46E5)], // Purple to Indigo
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 24),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Khóa diện mạo thực',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mở khóa khi đạt 100% độ thân mật. Hãy để tâm hồn kết nối trước khi ánh mắt chạm nhau.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // C. Nút Hành Động (Row)
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), // Slate-800
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            label: const Text('Viết lại tâm trạng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  // D. Những Mảnh Ghép (Sở Thích)
  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.volunteer_activism_rounded, color: Color(0xFFE11D48), size: 22),
            SizedBox(width: 8),
            Text(
              'Những mảnh ghép',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildHobbyChip(Icons.headphones_rounded, 'Nhạc Lofi & Indie', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)), // Indigo
            _buildHobbyChip(Icons.coffee_rounded, 'Cà phê đen', const Color(0xFFFEF3C7), const Color(0xFFD97706)), // Amber/Brown
            _buildHobbyChip(Icons.menu_book_rounded, 'Đọc sách đêm', const Color(0xFFECFDF5), const Color(0xFF059669)), // Emerald
            _buildHobbyChip(Icons.nights_stay_rounded, 'Thức khuya', const Color(0xFFF1F5F9), const Color(0xFF475569)), // Slate
          ],
        ),
      ],
    );
  }

  Widget _buildHobbyChip(IconData icon, String text, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: iconColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // E. Góc Tâm Hồn (Vibe Gallery)
  Widget _buildVibeCorner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Color(0xFF4F46E5), size: 22), // Indigo
            SizedBox(width: 8),
            Text(
              'Góc tâm hồn (Vibe)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Lưu giữ những khoảnh khắc không lộ mặt.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // Để bóng không bị cắt
            children: [
              _buildVibeImageCard('https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=400&q=80'),
              _buildVibeImageCard('https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=400&q=80'),
              _buildAddVibeCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVibeImageCard(String imageUrl) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            // Lớp Gradient đen dưới đáy làm sâu ảnh
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddVibeCard() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        // Mô phỏng nét đứt bằng border màu nhạt (hoặc dùng thư viện dotted_border nếu muốn thực sự đứt khúc)
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid, width: 2), 
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 32, color: Color(0xFF94A3B8)),
          SizedBox(height: 6),
          Text('Thêm Vibe', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // F. Chiều Sâu Tâm Lý (Biểu đồ tính cách)
  Widget _buildPersonalityChart() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chiều sâu tâm lý',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProgressItem('Đa sầu đa cảm', 0.85, const Color(0xFF4F46E5), const Color(0xFFE0E7FF)), // Indigo
              _buildProgressItem('Bình yên', 0.60, const Color(0xFF06B6D4), const Color(0xFFCFFAFE)), // Cyan
              _buildProgressItem('Bí ẩn', 0.92, const Color(0xFFA855F7), const Color(0xFFF3E8FF)), // Purple
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color mainColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mainColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
            ),
          ),
        ],
      ),
    );
  }

  // G. Nút Rời Khỏi Không Gian Này (Logout)
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(AuthLogoutRequested());
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFE4E6), width: 1.5), // Rose-100
          ),
        ),
        icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFE11D48), size: 20),
        label: const Text(
          'Rời khỏi không gian này',
          style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}