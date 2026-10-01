import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_event.dart';
import 'package:fatelinkfe/logic/blocs/home/home_state.dart';
import 'package:fatelinkfe/logic/blocs/main/main_bloc.dart';
import 'package:fatelinkfe/logic/blocs/main/main_event.dart';
import 'package:fatelinkfe/presentation/widgets/onboarding_modal.dart';
import 'package:fatelinkfe/presentation/widgets/shimmer_user_card.dart';
import 'package:fatelinkfe/presentation/screens/profile/user_detail_screen.dart';
import 'package:fatelinkfe/presentation/screens/match/match_chat_screen.dart';

import 'widgets/home_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_online_stories.dart';
import 'widgets/home_filter_chips.dart';
import 'widgets/soul_match_card.dart';
import 'widgets/radar_scanner_modal.dart';

class HomeScreen extends StatefulWidget {
  final bool showOnboarding;
  final VoidCallback onStartChat;
  final VoidCallback? onDismissOnboarding;

  const HomeScreen({
    super.key,
    required this.showOnboarding,
    required this.onStartChat,
    this.onDismissOnboarding,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  String? _userHandle;
  String? _avatarUrl;
  String? _currentUserMood;
  String? _currentUserMoodIcon;
  String? _currentUserFrequency;
  bool _showRetakeRadar = false;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    if (!widget.showOnboarding) {
      context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
    }
  }

  Future<void> _loadUserInfo() async {
    const secureStorage = FlutterSecureStorage();
    final name = await secureStorage.read(key: 'userName');
    final avatar = await secureStorage.read(key: 'avatarUrl');

    final prefs = await SharedPreferences.getInstance();
    final mood = prefs.getString('user_frequency_mood');
    final icon = prefs.getString('user_frequency_icon');
    final hertz = prefs.getString('user_frequency_hertz');

    if (mounted) {
      setState(() {
        _userName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
        if (_userName != null) {
          _userHandle = '@${_userName!.toLowerCase().replaceAll(' ', '')}';
        }
        _avatarUrl = (avatar != null && avatar.trim().isNotEmpty) ? avatar.trim() : null;
        _currentUserMood = mood;
        _currentUserMoodIcon = icon;
        _currentUserFrequency = hertz;
      });
    }
  }

  List<MatchUser> _filterUsers(List<MatchUser> users) {
    if (_selectedFilterIndex == 0) return users; // Tất cả
    final filterName = HomeFilterChips.filters[_selectedFilterIndex]['label'] as String;
    if (filterName == 'Gần bạn') return users; // Tất cả ứng viên xung quanh
    return users.where((u) {
      return u.emotion.toLowerCase().contains(filterName.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafePadding = 160.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Slate & Clean Canvas
      body: Stack(
        children: [
          // --- Nền Mesh Gradient (Magenta, Indigo, Cyan Ambient) ---
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x35EC4899), // Neon Magenta mờ
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x286366F1), // Soft Indigo mờ
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x2500E5FF), // Cyan Neon mờ
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox(),
            ),
          ),

          // --- Nội dung chính ---
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFFEC4899),
              backgroundColor: Colors.white,
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                await _loadUserInfo();
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header (User Avatar, PRO Badge & Action Icons)
                      HomeHeader(
                        avatarUrl: _avatarUrl,
                        userName: _userName,
                        userHandle: _userHandle,
                        onSearchTap: () => Navigator.of(context).pushNamed('/matches'),
                        onQrTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng quét mã QR đang được thử nghiệm'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        onNotificationTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chưa có thông báo mới'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        onSettingsTap: () {
                          context.read<MainBloc>().add(const ChangeTabEvent(3));
                        },
                      ),

                      const SizedBox(height: 12),

                      // 2. Hero Banner "Trợ lý AI Faye"
                      HomeHeroBanner(
                        onStartChat: widget.onStartChat,
                        onExplore: () {
                          RadarScannerModal.show(
                            context,
                            onConnectMatch: () => Navigator.of(context).pushNamed('/matches'),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 3. Online Avatars / Stories tâm trạng
                      HomeOnlineStories(
                        currentUserAvatar: _avatarUrl,
                        currentUserMood: _currentUserMood,
                        currentUserMoodIcon: _currentUserMoodIcon,
                        currentUserFrequency: _currentUserFrequency,
                        onRetakeRadar: () {
                          setState(() => _showRetakeRadar = true);
                        },
                        onAddStory: () {
                          setState(() => _showRetakeRadar = true);
                        },
                        onUserTap: (user) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tần số của ${user['name']}: ${user['status']} ${user['mood']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 4. Tiêu đề mục "Kết nối tâm hồn" & Nút "Xem tất cả"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Kết nối tâm hồn',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 16),
                              ],
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/matches'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 5. Filter Chips (Tất cả, Cô đơn, Phấn khích, Deep talk, Gần bạn)
                      HomeFilterChips(
                        selectedIndex: _selectedFilterIndex,
                        onSelected: (index) {
                          setState(() => _selectedFilterIndex = index);
                        },
                      ),

                      const SizedBox(height: 10),

                      // 6. Danh sách Card người dùng tương thích (Soul Match Feed)
                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.only(bottom: bottomSafePadding),
                              itemCount: 3,
                              itemBuilder: (context, index) => const ShimmerUserCard(),
                            );
                          }

                          final filteredUsers = _filterUsers(state.matchedUsers);

                          if (filteredUsers.isEmpty) {
                            return Container(
                              height: 160,
                              margin: EdgeInsets.only(bottom: bottomSafePadding),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bubble_chart_outlined, color: Colors.blueGrey.shade300, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFilterIndex == 0
                                        ? 'TalkWithFaye'.tr()
                                        : 'Không tìm thấy người cùng tần số này',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade400,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (_selectedFilterIndex != 0) ...[
                                    const SizedBox(height: 6),
                                    TextButton(
                                      onPressed: () => setState(() => _selectedFilterIndex = 0),
                                      child: const Text('Xem tất cả tần số', style: TextStyle(color: Color(0xFF6366F1))),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.only(bottom: bottomSafePadding),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return SoulMatchCard(
                                user: user,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(user: user),
                                  ),
                                ),
                                onChat: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MatchChatScreen(
                                      partnerId: user.id,
                                      partnerName: user.name,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Modal Onboarding (nếu người dùng lần đầu vào hoặc muốn quét lại tần số)
          if (widget.showOnboarding || _showRetakeRadar)
            OnboardingModal(
              onStartChat: () {
                setState(() => _showRetakeRadar = false);
                _loadUserInfo();
                widget.onStartChat();
              },
              onDismiss: () {
                setState(() => _showRetakeRadar = false);
                _loadUserInfo();
                context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                widget.onDismissOnboarding?.call();
              },
            ),
        ],
      ),
    );
  }
}
