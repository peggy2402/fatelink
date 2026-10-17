import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/toast_utils.dart';
import '../../../data/models/match_filter_criteria.dart';
import '../../../data/models/match_user.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import '../../../logic/blocs/home/home_event.dart';
import '../../../logic/blocs/home/home_state.dart';
import '../../widgets/cosmic_pulse_received_modal.dart';
import '../match/match_chat_screen.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/soul_connections_empty_state.dart';
import 'widgets/soul_connections_filter_bar.dart';
import 'widgets/soul_connections_grid_card.dart';
import 'widgets/soul_connections_header.dart';
import 'widgets/soul_connections_search_bar.dart';
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

  void _navigateToUserDetail(MatchUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  void _navigateToChat(MatchUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchChatScreen(
          partnerId: user.id,
          partnerName: user.displayName,
        ),
      ),
    );
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
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    final count = _criteria
                        .apply(state.matchedUsers, searchQuery: _searchQuery)
                        .length;
                    return SoulConnectionsHeader(
                      matchCount: count,
                      isSearchExpanded: _isSearchExpanded,
                      isGridView: _isGridView,
                      onBack: () => Navigator.of(context).pop(),
                      onToggleSearch: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                          if (!_isSearchExpanded) {
                            _searchController.clear();
                          }
                        });
                      },
                      onToggleViewMode: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    );
                  },
                ),

                // 2. Thanh tìm kiếm (Collapsible / Toggleable)
                if (_isSearchExpanded)
                  SoulConnectionsSearchBar(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    onClear: () => _searchController.clear(),
                  ),

                // 3. Thanh bộ lọc nhanh & Nút chuyển chế độ xem
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return SoulConnectionsFilterBar(
                      criteria: _criteria,
                      onOpenFilterModal: () => _openFilterModal(state.matchedUsers),
                      onToggleGender: () {
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
                      onToggleScope: () {
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
                    );
                  },
                ),

                const SizedBox(height: 8),

                // 4. Nội dung danh sách / Lưới kết nối
                Expanded(
                  child: BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.status == HomeStatus.loading &&
                          state.matchedUsers.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      final allUsers = state.matchedUsers;
                      final filteredUsers = _criteria.apply(
                        allUsers,
                        searchQuery: _searchQuery,
                      );

                      if (filteredUsers.isEmpty) {
                        return SoulConnectionsEmptyState(
                          onResetFilter: () {
                            setState(() {
                              _criteria = const MatchFilterCriteria();
                              _searchController.clear();
                            });
                          },
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<HomeBloc>()
                              .add(RefreshRecommendationsEvent(context));
                        },
                        color: const Color(0xFF6366F1),
                        child: _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.68,
                                ),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return SoulConnectionsGridCard(
                                    user: user,
                                    onTap: () => _navigateToUserDetail(user),
                                    onAction: () {
                                      if (user.isMutualFollow) {
                                        _navigateToChat(user);
                                      } else {
                                        _handleSendWave(user);
                                      }
                                    },
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                cacheExtent: 600.0,
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return SoulMatchCard(
                                    user: user,
                                    onTap: () => _navigateToUserDetail(user),
                                    onChat: () => _navigateToChat(user),
                                  );
                                },
                              ),
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
}
