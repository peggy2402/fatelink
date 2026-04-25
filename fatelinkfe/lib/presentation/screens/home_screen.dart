import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/presentation/widgets/onboarding_modal.dart';
import 'package:fatelinkfe/presentation/widgets/shimmer_user_card.dart';
import 'package:fatelinkfe/presentation/screens/user_detail_screen.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Nếu không bị chặn bởi Onboarding, tự động tải dữ liệu
    if (!widget.showOnboarding) {
      context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
    }

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.8).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      body: Stack(
        children: [
          // --- Nền Mesh Gradient Dark Theme ---
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0066FF), // Đổi blob đỏ thành xanh dương
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0066FF), // Fatelink Blue
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: const SizedBox(),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Thanh tiêu đề)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'The Matchmaker',
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // List Cards
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
                        return Expanded(
                            child: ListView.builder(
                              itemCount: 3, // Hiển thị 3 thẻ shimmer
                              itemBuilder: (context, index) =>
                                  const ShimmerUserCard(),
                            ),
                          );
                      }
                      
                      if (state.matchedUsers.isEmpty) {
                        return Expanded(
                            child: Center(
                              child: Text(
                                'TalkWithFaye'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                      }

                      return Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFFBD114A), // Màu vòng xoay
                              backgroundColor: const Color(0xFF001520),
                              onRefresh: () async {
                                context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                                await Future.delayed(const Duration(milliseconds: 800)); // Delay để UX vòng xoay mượt hơn
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(), // Đảm bảo luôn kéo được
                                padding: const EdgeInsets.only(
                                  bottom: 100,
                                  top: 8,
                                ),
                                itemCount: state.matchedUsers.length,
                                itemBuilder: (context, index) =>
                                    _buildUserCard(state.matchedUsers[index]),
                              ),
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Lớp Modal Onboarding ---
          if (widget.showOnboarding)
            OnboardingModal(onStartChat: widget.onStartChat),
        ],
      ),
    );
  }

  // Thiết kế Thẻ Người Dùng Ẩn Danh
  Widget _buildUserCard(MatchUser user) {
    // Đổi dải màu sang tone xanh và trắng
    final waveColors = [
      Colors.lightBlue.shade300,
      Colors.white,
      Colors.cyanAccent,
      Colors.blue.shade700,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03), // Glassmorphism cực mờ
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar Ẩn Danh với hiệu ứng nhịp thở
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, child) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF001520),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          _glowAnimation.value,
                        ), // Viền thở màu trắng
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(
                            _glowAnimation.value * 0.3,
                          ),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    // Avatar dạng abstract AI waves
                    child: const Center(
                      child: Icon(
                        Icons.waves_rounded,
                        color: Colors.white70,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),

              // Nội dung bên trong thẻ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq,
                          color:
                              waveColors[user.id.hashCode % waveColors.length],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tần số: ${user.emotion}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${user.compatibilityScore}% Tương hợp', // Lấy dữ liệu thật từ API
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
