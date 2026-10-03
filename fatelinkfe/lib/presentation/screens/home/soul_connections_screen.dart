import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/match_filter_criteria.dart';
import '../../../data/models/match_user.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import '../../../logic/blocs/home/home_event.dart';
import '../../../logic/blocs/home/home_state.dart';
import '../../widgets/cosmic_pulse_received_modal.dart';
import '../match/match_chat_screen.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/soul_filter_modal.dart';
import 'widgets/soul_match_card.dart';

class SoulConnectionsScreen extends StatefulWidget {
  final MatchFilterCriteria? initialFilter;
  final bool isSearchInitiallyOpen;

  const SoulConnectionsScreen({
    super.key,
    this.initialFilter,
    this.isSearchInitiallyOpen = false,
  });

  @override
  State<SoulConnectionsScreen> createState() => _SoulConnectionsScreenState();
}

class _SoulConnectionsScreenState extends State<SoulConnectionsScreen> {
  late MatchFilterCriteria _criteria;
  bool _isGridView = true; // Chuyển đổi giữa dạng Lưới (Grid) và Danh sách (List)
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isSearchExpanded = widget.isSearchInitiallyOpen;
    _criteria = widget.initialFilter ?? const MatchFilterCriteria();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal(List<MatchUser> allUsers) async {
    final result = await SoulFilterModal.show(
      context,
      initialCriteria: _criteria,
      allUsers: allUsers,
      onApply: (newCriteria) {
        setState(() {
          _criteria = newCriteria;
        });
      },
    );

    if (result != null && mounted) {
      setState(() {
        _criteria = result;
      });
    }
  }

  void _handleSendWave(MatchUser user) {
    HapticFeedback.mediumImpact();
    ToastUtil.showSuccess(
      context,
      'Đã phát sóng 432Hz tới ${user.displayName}! Tín hiệu đang lan tỏa ✨',
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        CosmicPulseReceivedModal.show(context, sender: user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Nền tinh vân mờ nhẹ
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Header & Thanh điều hướng
                _buildHeader(),

                // 2. Thanh tìm kiếm (Collapsible / Toggleable)
                if (_isSearchExpanded) _buildSearchBar(),

                // 3. Thanh bộ lọc nhanh & Nút chuyển chế độ xem
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return _buildFilterBar(state.matchedUsers);
                  },
                ),

                const SizedBox(height: 8),

                // 4. Nội dung danh sách / Lưới kết nối
                Expanded(
                  child: BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.status == HomeStatus.loading && state.matchedUsers.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      final allUsers = state.matchedUsers;
                      final filteredUsers = _criteria.apply(allUsers, searchQuery: _searchQuery);

                      if (filteredUsers.isEmpty) {
                        return _buildEmptyState(allUsers);
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
                        },
                        color: const Color(0xFF6366F1),
                        child: _isGridView
                            ? _buildGridView(filteredUsers)
                            : _buildListView(filteredUsers),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Nút quay lại
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Tiêu đề & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Kết nối tâm hồn',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    final count = _criteria.apply(state.matchedUsers, searchQuery: _searchQuery).length;
                    return Text(
                      '$count tần số đồng điệu phù hợp',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Nút Tìm kiếm
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSearchExpanded
                    ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSearchExpanded
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                size: 20,
                color: _isSearchExpanded
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nút Chuyển đổi Grid / List
          GestureDetector(
            onTap: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                size: 19,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Thanh tìm kiếm ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Tìm theo bí danh, cảm xúc, #hashtag...',
            hintStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: const Color(0xFF64748B),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // --- Thanh bộ lọc nhanh & Nút Bộ lọc chi tiết ---
  Widget _buildFilterBar(List<MatchUser> allUsers) {
    final activeCount = _criteria.activeFilterCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Nút mở Modal Bộ lọc chính
          GestureDetector(
            onTap: () => _openFilterModal(allUsers),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? const Color(0xFF6366F1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeCount > 0
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
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
                    size: 15,
                    color: activeCount > 0 ? Colors.white : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: activeCount > 0 ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEC4899),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 10,
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

          // Chip lọc Giới tính nhanh
          _buildQuickFilterChip(
            label: _criteria.gender == 'all'
                ? 'Giới tính'
                : (_criteria.gender == 'female' ? 'Nữ' : 'Nam'),
            isActive: _criteria.gender != 'all',
            icon: Icons.wc_rounded,
            onTap: () {
              // Xoay vòng Tất cả -> Nữ -> Nam -> Tất cả
              setState(() {
                if (_criteria.gender == 'all') {
                  _criteria = _criteria.copyWith(gender: 'female');
                } else if (_criteria.gender == 'female') {
                  _criteria = _criteria.copyWith(gender: 'male');
                } else {
                  _criteria = _criteria.copyWith(gender: 'all');
                }
              });
            },
          ),

          const SizedBox(width: 8),

          // Chip lọc Khu vực nhanh
          _buildQuickFilterChip(
            label: _criteria.locationScope == 'nearby'
                ? 'Gần bạn (< 5km)'
                : (_criteria.locationScope == 'city'
                    ? 'Trong thành phố'
                    : 'Toàn quốc'),
            isActive: _criteria.locationScope != 'all',
            icon: Icons.location_on_rounded,
            onTap: () {
              // Xoay vòng Toàn quốc -> Gần bạn -> Trong thành phố -> Toàn quốc
              setState(() {
                if (_criteria.locationScope == 'all') {
                  _criteria = _criteria.copyWith(locationScope: 'nearby');
                } else if (_criteria.locationScope == 'nearby') {
                  _criteria = _criteria.copyWith(locationScope: 'city');
                } else {
                  _criteria = _criteria.copyWith(locationScope: 'all');
                }
              });
            },
          ),

          const SizedBox(width: 8),

          // Chip lọc Độ tuổi nhanh
          _buildQuickFilterChip(
            label: '${_criteria.ageRange.start.round()}-${_criteria.ageRange.end.round()} tuổi',
            isActive: _criteria.ageRange.start > 18 || _criteria.ageRange.end < 45,
            icon: Icons.cake_rounded,
            onTap: () => _openFilterModal(allUsers),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dạng Lưới 2 cột (Grid View) ---
  Widget _buildGridView(List<MatchUser> users) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildGridCard(user);
      },
    );
  }

  Widget _buildGridCard(MatchUser user) {
    final distance = user.distanceKm != null
        ? '${user.distanceKm} km'
        : '${((user.id.hashCode.abs() % 45) / 10.0 + 0.5).toStringAsFixed(1)} km';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(user: user),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Avatar trung tâm với hào quang mờ
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.20),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          AnonymousAvatarHelper.buildAvatar(
                            user: user,
                            size: 68,
                            showLockBadge: !user.canViewIdentity,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Thông tin tên, tuổi, giới tính & cự ly
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (!user.canViewIdentity) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: Color(0xFFEC4899),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${user.resolvedAge} tuổi • ${user.genderLabel}',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 3. Tần số cảm xúc pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tần số: ${user.moodIcon != null ? "${user.moodIcon} " : ""}${user.emotion}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),

                  // 4. Nút Hành Động: Trò chuyện (nếu đã kết nối) hoặc Gửi sóng 432Hz
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        if (user.isMutualFollow) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MatchChatScreen(
                                partnerId: user.id,
                                partnerName: user.displayName,
                              ),
                            ),
                          );
                        } else {
                          _handleSendWave(user);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: user.isMutualFollow
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.isMutualFollow
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.bolt_rounded,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.isMutualFollow ? 'Trò chuyện' : 'Gửi sóng 432Hz',
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Huy hiệu % tương thích góc trên bên phải
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      '${user.compatibilityScore}%',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dạng Danh sách thẻ đầy đủ (List View) ---
  Widget _buildListView(List<MatchUser> users) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      cacheExtent: 600.0,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return SoulMatchCard(
          user: user,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserDetailScreen(user: user),
              ),
            );
          },
          onChat: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MatchChatScreen(
                  partnerId: user.id,
                  partnerName: user.displayName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Trạng thái trống (Empty State) ---
  Widget _buildEmptyState(List<MatchUser> allUsers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 38,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa tìm thấy tần số phù hợp',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử nới lỏng bán kính khoảng cách hoặc mở rộng độ tuổi để tìm thấy nhiều bạn đồng điệu hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _criteria = const MatchFilterCriteria();
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Đặt lại bộ lọc',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
