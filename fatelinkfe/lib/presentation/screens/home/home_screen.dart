import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/core/utils/secure_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/core/services/app_permission_service.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_event.dart';
import 'package:fatelinkfe/logic/blocs/home/home_state.dart';
import 'package:fatelinkfe/presentation/widgets/onboarding_modal.dart';
import 'package:fatelinkfe/presentation/widgets/shimmer_user_card.dart';
import 'package:fatelinkfe/presentation/screens/profile/user_detail_screen.dart';
import 'package:fatelinkfe/presentation/screens/match/match_chat_screen.dart';

import 'widgets/home_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_online_stories.dart';
import 'widgets/soul_match_card.dart';
import 'widgets/soul_filter_modal.dart';
import '../match/cosmic_broadcast_screen.dart';
import 'widgets/qr_hub_modal.dart';
import 'widgets/notifications_modal.dart';
import 'soul_connections_screen.dart';
import '../settings/settings_detail_screen.dart';
import 'package:fatelinkfe/data/models/match_filter_criteria.dart';
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
  bool _hasUnreadNotification = true;
  MatchFilterCriteria _filterCriteria = const MatchFilterCriteria();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    if (!widget.showOnboarding) {
      context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
    }
    // Xin cấp quyền vị trí thân thiện khi khởi động app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppPermissionService.checkAndRequestInitialPermissions(context);
      }
    });
  }

  void _openFilterModal(List<MatchUser> allUsers) async {
    final result = await SoulFilterModal.show(
      context,
      initialCriteria: _filterCriteria,
      allUsers: allUsers,
      onApply: (newCriteria) {
        setState(() {
          _filterCriteria = newCriteria;
        });
      },
    );

    if (result != null && mounted) {
      setState(() {
        _filterCriteria = result;
      });
    }
  }

  Widget _buildFilterChipItem({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await SecureStorageHelper.read('userName');
    final avatar = await SecureStorageHelper.read('avatarUrl');

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

          if (realName != null) await SecureStorageHelper.write('userName', realName.toString());
          if (realAvatar != null) await SecureStorageHelper.write('avatarUrl', realAvatar.toString());
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
                    // 1. Header kính mờ ghim cố định (Facebook/Instagram style) bảo vệ Status Bar & Dynamic Island
                    SliverAppBar(
                      floating: false,
                      snap: false,
                      pinned: true,
                      elevation: 0,
                      scrolledUnderElevation: 2.0,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                        statusBarBrightness: Brightness.light,
                      ),
                      centerTitle: false,
                      toolbarHeight: 74.0,
                      automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      flexibleSpace: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC).withValues(alpha: 0.88),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: HomeHeader(
                        avatarUrl: _avatarUrl,
                        userName: _userName,
                        userHandle: _userHandle,
                        hasNotification: _hasUnreadNotification,
                        onSearchTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SoulConnectionsScreen(
                                initialFilter: _filterCriteria,
                                isSearchInitiallyOpen: true,
                              ),
                            ),
                          );
                        },
                        onQrTap: () {
                          QrHubModal.show(
                            context,
                            userName: _userName,
                            userHandle: _userHandle,
                            avatarUrl: _avatarUrl,
                          );
                        },
                        onNotificationTap: () {
                          NotificationsModal.show(
                            context,
                            onClearBadge: () {
                              setState(() {
                                _hasUnreadNotification = false;
                              });
                            },
                          );
                        },
                        onSettingsTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsDetailScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // 2. Banner AI Faye, Stories tâm trạng, Tiêu đề kết nối
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Hero Banner "Trợ lý AI Faye"
                          HomeHeroBanner(
                            onStartChat: widget.onStartChat,
                            onExplore: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CosmicBroadcastScreen(),
                                ),
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
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => SoulConnectionsScreen(
                                          initialFilter: _filterCriteria,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  child: const Text('Xem tất cả'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Bộ lọc đa chiều (Nút Lọc Modal + Giới tính + Khu vực + Độ tuổi)
                          BlocBuilder<HomeBloc, HomeState>(
                            builder: (context, state) {
                              final activeCount = _filterCriteria.activeFilterCount;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    // 1. Nút mở Modal Bộ lọc chính
                                    GestureDetector(
                                      onTap: () => _openFilterModal(state.matchedUsers),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                                        decoration: BoxDecoration(
                                          color: activeCount > 0
                                              ? const Color(0xFF6366F1)
                                              : Colors.white.withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: activeCount > 0
                                                ? const Color(0xFF6366F1)
                                                : const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (activeCount > 0 ? const Color(0xFF6366F1) : Colors.black)
                                                  .withValues(alpha: activeCount > 0 ? 0.25 : 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              size: 14,
                                              color: activeCount > 0 ? Colors.white : const Color(0xFF6366F1),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Bộ lọc',
                                              style: TextStyle(
                                                fontFamily: 'BeVietnamPro',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: activeCount > 0 ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (activeCount > 0) ...[
                                              const SizedBox(width: 5),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFEC4899),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '$activeCount',
                                                  style: const TextStyle(
                                                    fontFamily: 'BeVietnamPro',
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // 2. Chip Lọc Giới tính nhanh
                                    _buildFilterChipItem(
                                      label: _filterCriteria.gender == 'all'
                                          ? 'Giới tính'
                                          : (_filterCriteria.gender == 'female' ? 'Nữ' : 'Nam'),
                                      isSelected: _filterCriteria.gender != 'all',
                                      icon: Icons.wc_rounded,
                                      onTap: () {
                                        setState(() {
                                          if (_filterCriteria.gender == 'all') {
                                            _filterCriteria = _filterCriteria.copyWith(gender: 'female');
                                          } else if (_filterCriteria.gender == 'female') {
                                            _filterCriteria = _filterCriteria.copyWith(gender: 'male');
                                          } else {
                                            _filterCriteria = _filterCriteria.copyWith(gender: 'all');
                                          }
                                        });
                                      },
                                    ),

                                    const SizedBox(width: 8),

                                    // 3. Chip Lọc Toàn quốc / Gần bạn / Trong thành phố
                                    _buildFilterChipItem(
                                      label: _filterCriteria.locationScope == 'nearby'
                                          ? 'Gần bạn (< 5km)'
                                          : (_filterCriteria.locationScope == 'city'
                                              ? 'Trong thành phố (< 25km)'
                                              : 'Toàn quốc'),
                                      isSelected: _filterCriteria.locationScope != 'all',
                                      icon: Icons.public_rounded,
                                      onTap: () {
                                        setState(() {
                                          if (_filterCriteria.locationScope == 'all') {
                                            _filterCriteria = _filterCriteria.copyWith(locationScope: 'nearby');
                                          } else if (_filterCriteria.locationScope == 'nearby') {
                                            _filterCriteria = _filterCriteria.copyWith(locationScope: 'city');
                                          } else {
                                            _filterCriteria = _filterCriteria.copyWith(locationScope: 'all');
                                          }
                                        });
                                      },
                                    ),

                                    const SizedBox(width: 8),

                                    // 4. Chip Lọc Độ tuổi
                                    _buildFilterChipItem(
                                      label: '${_filterCriteria.ageRange.start.round()}-${_filterCriteria.ageRange.end.round()} tuổi',
                                      isSelected: _filterCriteria.ageRange.start > 18 || _filterCriteria.ageRange.end < 45,
                                      icon: Icons.cake_rounded,
                                      onTap: () => _openFilterModal(state.matchedUsers),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),
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

                          final matchedUsers = _filterCriteria.apply(state.matchedUsers);

                          if (matchedUsers.isEmpty) {
                            final bool isFiltered = !_filterCriteria.isDefault;
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
                                    child: Center(
                                      child: Icon(
                                        isFiltered ? Icons.filter_alt_off_rounded : Icons.radar_rounded,
                                        color: const Color(0xFF6366F1),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    isFiltered ? 'Chưa có ai phù hợp bộ lọc' : 'Chưa có tín hiệu xung quanh',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isFiltered
                                        ? 'Hiện tại chưa có người dùng nào khớp với tiêu chí bạn chọn. Hãy thử nới lỏng bộ lọc nhé!'
                                        : 'Bạn đang là người duy nhất phát sóng bước sóng hôm nay! Khi có người dùng thật khác tham gia, họ sẽ xuất hiện tại đây.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (isFiltered)
                                    ElevatedButton.icon(
                                      onPressed: () => setState(() => _filterCriteria = const MatchFilterCriteria()),
                                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                      label: const Text('Đặt lại bộ lọc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                    )
                                  else
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
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: bottomSafePadding),
                            child: Column(
                              children: matchedUsers.map((user) {
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
                                        partnerName: user.displayName,
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
