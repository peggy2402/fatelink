import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/core/utils/secure_storage_helper.dart';
import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:fatelinkfe/core/utils/toast_utils.dart';
import 'package:fatelinkfe/services/api_service.dart';
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
import 'widgets/home_quick_filter_bar.dart';
import 'widgets/home_feed_empty_state.dart';
import 'widgets/home_cosmic_background.dart';
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

  Future<void> _handleToggleLikeUser(MatchUser user) async {
    final token = await SecureStorageHelper.read('accessToken');
    if (token == null || user.id.isEmpty) return;
    if (!mounted) return;

    final url = '${AppConstants.baseUrl}/${AppConstants.userToggleLike(user.id)}';
    try {
      final res = await ApiService.post(url, context, token: token);
      if (res != null && mounted) {
        final isLiked = res['isLiked'] == true;
        final isMutual = res['isMutual'] == true;

        if (isMutual) {
          ToastUtil.showSuccess(
            context,
            '✨ Định mệnh giao thoa! Bạn và ${user.displayName} đã cùng thả tim! Diện mạo đã được mở khóa.',
          );
        } else if (isLiked) {
          ToastUtil.showSuccess(
            context,
            'Đã thả tim kết nối cùng ${user.displayName} 💕',
          );
        } else {
          ToastUtil.showInfo(context, 'Đã bỏ thả tim ${user.displayName}');
        }

        context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
      }
    } catch (e) {
      debugPrint('Lỗi thả tim: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafePadding = 160.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Slate & Clean Canvas
      body: Stack(
        children: [
          // --- Nền Cosmic Mesh Gradient siêu mượt (Zero GPU Overhead) ---
          const HomeCosmicBackground(),

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
                              return HomeQuickFilterBar(
                                filterCriteria: _filterCriteria,
                                onOpenFilterModal: () => _openFilterModal(state.matchedUsers),
                                onCriteriaChanged: (newCriteria) {
                                  setState(() {
                                    _filterCriteria = newCriteria;
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    // 3. Danh sách Card người dùng tương thích (Soul Match Feed - Tối ưu 60-120fps cuộn mượt mà với SliverList.builder & RepaintBoundary)
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
                          return SliverPadding(
                            padding: EdgeInsets.only(bottom: bottomSafePadding),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => const ShimmerUserCard(),
                                childCount: 3,
                              ),
                            ),
                          );
                        }

                        final matchedUsers = _filterCriteria.apply(state.matchedUsers);

                        if (matchedUsers.isEmpty) {
                          return SliverToBoxAdapter(
                            child: HomeFeedEmptyState(
                              isFiltered: !_filterCriteria.isDefault,
                              bottomSafePadding: bottomSafePadding,
                              onResetFilter: () => setState(() => _filterCriteria = const MatchFilterCriteria()),
                              onStartChat: () => widget.onStartChat(),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: EdgeInsets.only(bottom: bottomSafePadding),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final user = matchedUsers[index];
                                return RepaintBoundary(
                                  key: ValueKey('user_card_${user.id}'),
                                  child: SoulMatchCard(
                                    user: user,
                                    onLike: () => _handleToggleLikeUser(user),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => UserDetailScreen(user: user),
                                        ),
                                      );
                                      if (context.mounted) {
                                        context.read<HomeBloc>().add(LoadRecommendationsEvent(context));
                                      }
                                    },
                                    onChat: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MatchChatScreen(
                                          partnerId: user.id,
                                          partnerName: user.displayName,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: matchedUsers.length,
                            ),
                          ),
                        );
                      },
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
