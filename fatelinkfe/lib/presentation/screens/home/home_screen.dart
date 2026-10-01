import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:fatelinkfe/core/utils/toast_utils.dart';
import 'package:fatelinkfe/data/repositories/profile_repository.dart';

class HomeScreen extends StatefulWidget {
  final bool showOnboarding;
  final VoidCallback onStartChat;
  final VoidCallback? onDismissOnboarding;
  final VoidCallback? onRetakeRadar;

  const HomeScreen({
    super.key,
    this.showOnboarding = false,
    required this.onStartChat,
    this.onDismissOnboarding,
    this.onRetakeRadar,
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

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserInfo();
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

    // Luôn đồng bộ dữ liệu thật mới nhất từ Backend API
    try {
      if (mounted) {
        final profileData = await ProfileRepository().fetchUserProfile(context);
        final realUser = profileData['data'] ?? profileData['user'] ?? profileData;
        if (realUser is Map<String, dynamic> && realUser.isNotEmpty) {
          final realName = realUser['name'] ?? realUser['displayName'];
          final realAvatar = realUser['avatar'];
          final realMood = realUser['latestEmotion'] ?? realUser['mood'];
          final realIcon = realUser['moodIcon'];
          final realHertz = realUser['frequencyHertz'];

          if (realName != null) await secureStorage.write(key: 'userName', value: realName.toString());
          if (realAvatar != null) await secureStorage.write(key: 'avatarUrl', value: realAvatar.toString());
          if (realMood != null) await prefs.setString('user_frequency_mood', realMood.toString());
          if (realIcon != null) await prefs.setString('user_frequency_icon', realIcon.toString());
          if (realHertz != null) await prefs.setString('user_frequency_hertz', realHertz.toString());

          if (mounted) {
            setState(() {
              if (realName != null) {
                _userName = realName.toString();
                _userHandle = '@${_userName!.toLowerCase().replaceAll(' ', '')}';
              }
              if (realAvatar != null) _avatarUrl = realAvatar.toString();
              if (realMood != null) _currentUserMood = realMood.toString();
              if (realIcon != null) _currentUserMoodIcon = realIcon.toString();
              if (realHertz != null) _currentUserFrequency = realHertz.toString();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Sync profile error: $e');
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
          Positioned.fill(
            child: RefreshIndicator(
              color: const Color(0xFFEC4899),
              backgroundColor: Colors.white,
              edgeOffset: MediaQuery.of(context).padding.top,
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                await _loadUserInfo();
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Header nổi tự động ẩn khi vuốt xuống và hiện lại ngay khi vuốt lên (Facebook style)
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      pinned: false,
                      elevation: 0,
                      scrolledUnderElevation: 3.0,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      centerTitle: false,
                      toolbarHeight: 74.0,
                      automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      flexibleSpace: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            color: const Color(0xFFF8FAFC).withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      title: HomeHeader(
                        avatarUrl: _avatarUrl,
                        userName: _userName,
                        userHandle: _userHandle,
                        onSearchTap: () => Navigator.of(context).pushNamed('/matches'),
                        onQrTap: () {
                          ToastUtil.showInfo(context, 'Tính năng quét mã QR đang được thử nghiệm');
                        },
                        onNotificationTap: () {
                          ToastUtil.showInfo(context, 'Chưa có thông báo mới ✨');
                        },
                        onSettingsTap: () {
                          context.read<MainBloc>().add(const ChangeTabEvent(3));
                        },
                      ),
                    ),

                    // 2. Banner AI Faye, Stories tâm trạng, Tiêu đề & Filter Chips
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Hero Banner "Trợ lý AI Faye"
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

                          // Online Avatars / Stories tâm trạng
                          BlocBuilder<HomeBloc, HomeState>(
                            builder: (context, state) {
                              return HomeOnlineStories(
                                currentUserAvatar: _avatarUrl,
                                currentUserMood: _currentUserMood,
                                currentUserMoodIcon: _currentUserMoodIcon,
                                currentUserFrequency: _currentUserFrequency,
                                onlineUsers: state.matchedUsers,
                                onRetakeRadar: () {
                                  if (widget.onRetakeRadar != null) {
                                    widget.onRetakeRadar!();
                                  } else {
                                    setState(() => _showRetakeRadar = true);
                                  }
                                },
                                onAddStory: () {
                                  if (widget.onRetakeRadar != null) {
                                    widget.onRetakeRadar!();
                                  } else {
                                    setState(() => _showRetakeRadar = true);
                                  }
                                },
                                onMatchUserTap: (user) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => UserDetailScreen(user: user),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Tiêu đề mục "Kết nối tâm hồn" & Nút "Xem tất cả"
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

                          // Filter Chips (Tất cả, Cô đơn, Phấn khích, Deep talk, Gần bạn)
                          HomeFilterChips(
                            selectedIndex: _selectedFilterIndex,
                            onSelected: (index) {
                              setState(() => _selectedFilterIndex = index);
                            },
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // 3. Danh sách Card người dùng tương thích (Soul Match Feed)
                    SliverToBoxAdapter(
                      child: BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: bottomSafePadding),
                              child: const Column(
                                children: [
                                  ShimmerUserCard(),
                                  ShimmerUserCard(),
                                  ShimmerUserCard(),
                                ],
                              ),
                            );
                          }

                          final filteredUsers = _filterUsers(state.matchedUsers);

                          if (filteredUsers.isEmpty) {
                            return Container(
                              margin: EdgeInsets.only(bottom: bottomSafePadding + 20, left: 16, right: 16),
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.radar_rounded, color: Color(0xFF6366F1), size: 30),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Chưa có tín hiệu xung quanh',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedFilterIndex == 0
                                        ? 'Bạn đang là người duy nhất phát sóng bước sóng hôm nay! Khi có người dùng thật khác tham gia, họ sẽ xuất hiện tại đây.'
                                        : 'Không tìm thấy người dùng nào cùng tần số bộ lọc này.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade500,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                  if (_selectedFilterIndex != 0) ...[
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () => setState(() => _selectedFilterIndex = 0),
                                      child: const Text('Xem tất cả tần số', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => widget.onStartChat(),
                                      icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                      label: const Text('Tâm sự cùng Faye AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: bottomSafePadding),
                            child: Column(
                              children: filteredUsers.map((user) {
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
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
