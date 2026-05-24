import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/presentation/widgets/onboarding_modal.dart';
import 'package:fatelinkfe/presentation/widgets/shimmer_user_card.dart';
import 'package:fatelinkfe/presentation/screens/profile/user_detail_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_event.dart';
import 'package:fatelinkfe/logic/blocs/home/home_state.dart';

class HomeScreen extends StatefulWidget {
  final bool showOnboarding;
  final VoidCallback onStartChat;

  const HomeScreen({
    super.key,
    required this.showOnboarding,
    required this.onStartChat,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    {
  final PageController _pageController = PageController();
  int _currentHeroPage = 0;

  @override
  void initState() {
    super.initState();
    
    if (!widget.showOnboarding) {
      context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Theme sáng sang trọng
      body: Stack(
        children: [
          // --- Nền Light Mesh Gradient & Neon Accents ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x40FFD1DC), // Light pink mờ
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3300E5FF), // Neon Cyan mờ
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x40E6E6FA), // Pale purple mờ
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFFBD114A),
              backgroundColor: Colors.white,
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ScrollConfiguration(
                // Ẩn thanh cuộn (scrollbar) để giao diện thoáng, tinh tế hơn
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF00E5FF), Color(0xFFFF69B4)], // Cyan to Pink neon
                                        ),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 22,
                                        backgroundImage: AssetImage('assets/images/default_avatar.png'),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent.shade400,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'John Doe',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2F4F4F),
                                      ),
                                    ),
                                    Text(
                                      '@johndoe',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF00B8D4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildHeaderIcon(Icons.search_rounded),
                                const SizedBox(width: 4),
                                _buildHeaderIcon(Icons.qr_code_scanner_rounded),
                                const SizedBox(width: 4),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildHeaderIcon(Icons.notifications_none_rounded),
                                    Positioned(
                                      right: 12,
                                      top: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF3B30),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                _buildHeaderIcon(Icons.settings_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- Hero Carousel ---
                      SizedBox(
                        height: 160,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentHeroPage = index;
                            });
                          },
                          children: [
                            _buildHeroCard('Trải nghiệm AI', 'Khám phá thế giới qua con mắt của Faye', Icons.auto_awesome, [const Color(0xFF9C27B0), const Color(0xFFFF69B4)]),
                            _buildHeroCard('Kết nối tâm giao', 'Tìm kiếm tần số tương đồng với bạn', Icons.favorite_rounded, [const Color(0xFFFF3B30), const Color(0xFFFF9500)]),
                            _buildHeroCard('Trò chuyện ẩn danh', 'Thoải mái chia sẻ không giới hạn', Icons.visibility_off, [const Color(0xFF00E5FF), const Color(0xFF007AFF)]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(_currentHeroPage == 0),
                          const SizedBox(width: 6),
                          _buildDot(_currentHeroPage == 1),
                          const SizedBox(width: 6),
                          _buildDot(_currentHeroPage == 2),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Đang trực tuyến ---
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Đang trực tuyến',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2F4F4F)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF007AFF)],
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 30,
                                      backgroundImage: AssetImage('assets/images/default_avatar.png'),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.shade400,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Danh sách tương hợp ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kết nối tâm hồn',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F4F4F)),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B8D4)),
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),

                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: 3,
                              itemBuilder: (context, index) => const ShimmerUserCard(),
                            );
                          }
                          
                          if (state.matchedUsers.isEmpty) {
                            return Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: Text(
                                'TalkWithFaye'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 120), // Đệm lớn cho khoảng trống Bottom Nav Bar
                            itemCount: state.matchedUsers.length,
                            itemBuilder: (context, index) => _buildUserCard(state.matchedUsers[index]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.showOnboarding)
            OnboardingModal(onStartChat: widget.onStartChat),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return IconButton(
      icon: Icon(icon, color: const Color(0xFF2F4F4F), size: 26),
      onPressed: () {},
    );
  }

  Widget _buildHeroCard(String title, String subtitle, IconData icon, List<Color> gradientColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFBD114A) : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildUserCard(MatchUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6), // Glassmorphism sáng
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE0F7FA), // Light Cyan
                    child: Icon(
                      Icons.waves_rounded,
                      color: Color(0xFF00B8D4),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Color(0xFF2F4F4F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.graphic_eq,
                              color: Color(0xFF9C27B0), // Neon Purple
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tần số: ${user.emotion}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF007AFF)], // Cyan to Blue neon gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${user.compatibilityScore}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
