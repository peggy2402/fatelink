import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/match_filter_criteria.dart';
import '../../../data/models/match_user.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import '../../../logic/blocs/home/home_event.dart';
import '../../../logic/blocs/home/home_state.dart';
import '../home/widgets/soul_filter_modal.dart';
import '../match/match_chat_screen.dart';
import '../profile/user_detail_screen.dart';

// Components & Widgets tách rời sạch sẽ
import 'widgets/cosmic_center_node.dart';
import 'widgets/cosmic_radar_canvas.dart';
import 'widgets/explore_background.dart';
import 'widgets/explore_grid_view.dart';
import 'widgets/explore_top_header.dart';
import 'widgets/floating_soul_node.dart';
import 'widgets/pulse_action_button.dart';
import 'widgets/radar_controls_cluster.dart';
import 'widgets/soul_peek_card.dart';

/// Màn hình Khám Phá Vũ Trụ Cảm Xúc (Cosmic Exploration Screen):
/// - Điều phối luồng dữ liệu & tương tác giữa các thành phần
/// - Hỗ trợ 2 chế độ: Vòm Radar 360° (Radar View) và Lưới Thẻ (Orbit Cards View)
/// - Cử chỉ Zoom đa điểm (Pinch-to-Zoom & Pan tự do kiểu Google Maps)
/// - Thuật toán phân bổ so le chống chồng lấn (Anti-Collision Polar Staggering)
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _sweepController;
  late AnimationController _waveController;
  late AnimationController _shockwaveController;
  late AnimationController _pulseFabController;

  // Điều khiển Thu phóng & Kéo rê Radar (Pinch-to-Zoom & Pan như Google Maps)
  late TransformationController _transformationController;
  late AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  double _currentScale = 1.0;

  // Trạng thái khám phá
  bool _isRadarView = true;
  String _selectedVibe = 'all';
  MatchFilterCriteria _filterCriteria = const MatchFilterCriteria();
  MatchUser? _selectedUser;
  String? _myAvatarUrl;



  @override
  void initState() {
    super.initState();

    // 1. Tia quét Radar 360 độ quay liên tục (chu kỳ 4.5s)
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    // 2. Sóng siêu âm lan tỏa liên tục (chu kỳ 2.8s)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // 3. Sóng xung kích khi bấm nút "Phát xung sóng" (900ms)
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 4. Nhịp đập của nút phát xung
    _pulseFabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // 5. Điều khiển Thu phóng & Kéo rê Radar (InteractiveViewer controller)
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);

    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });

    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    final avatar = await SecureStorageHelper.read('avatarUrl');
    if (mounted && avatar != null && avatar.isNotEmpty) {
      setState(() => _myAvatarUrl = avatar);
    }
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.04) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _animateToMatrix(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _zoomAnimController,
      curve: Curves.easeOutCubic,
    ));
    _zoomAnimController.forward(from: 0.0);
  }

  void _zoomIn(Offset focalCenter) {
    HapticFeedback.lightImpact();
    final current = _transformationController.value;
    final delta = Matrix4.translationValues(focalCenter.dx, focalCenter.dy, 0.0) *
        Matrix4.diagonal3Values(1.35, 1.35, 1.0) *
        Matrix4.translationValues(-focalCenter.dx, -focalCenter.dy, 0.0);
    final target = delta * current;
    if (target.getMaxScaleOnAxis() > 3.8) return;
    _animateToMatrix(target);
  }

  void _zoomOut(Offset focalCenter) {
    HapticFeedback.lightImpact();
    final current = _transformationController.value;
    final delta = Matrix4.translationValues(focalCenter.dx, focalCenter.dy, 0.0) *
        Matrix4.diagonal3Values(0.74, 0.74, 1.0) *
        Matrix4.translationValues(-focalCenter.dx, -focalCenter.dy, 0.0);
    final target = delta * current;
    if (target.getMaxScaleOnAxis() < 0.55) return;
    _animateToMatrix(target);
  }

  void _recenterRadar() {
    HapticFeedback.mediumImpact();
    ToastUtil.showInfo(context, 'Đã đưa Radar về tâm sóng ban đầu 🎯');
    _animateToMatrix(Matrix4.identity());
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _waveController.dispose();
    _shockwaveController.dispose();
    _pulseFabController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _zoomAnimController.dispose();
    super.dispose();
  }

  /// Kích hoạt phát xung sóng quét mới (Sonar Pulse)
  void _triggerSonarPulse() {
    HapticFeedback.mediumImpact();
    _shockwaveController.forward(from: 0.0);

    // Tăng tốc quét nhanh trong 1.4s tạo hiệu ứng kích hoạt
    _sweepController.animateTo(
      _sweepController.value + 2.0,
      duration: const Duration(milliseconds: 1400),
      curve: Curves.fastOutSlowIn,
    ).then((_) {
      if (mounted) _sweepController.repeat();
    });

    // Làm mới dữ liệu từ HomeBloc
    context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));

    ToastUtil.showSuccess(
      context,
      'Đã phát xung sóng 432Hz trong bán kính 10km quanh bạn!',
    );
  }

  /// Mở modal bộ lọc chuyên sâu
  void _openFilterModal(List<MatchUser> allUsers) async {
    final result = await SoulFilterModal.show(
      context,
      initialCriteria: _filterCriteria,
      allUsers: allUsers,
      onApply: (newCriteria) {
        setState(() => _filterCriteria = newCriteria);
      },
    );

    if (result != null && mounted) {
      setState(() => _filterCriteria = result);
    }
  }

  /// Tổng hợp danh sách người dùng thực tế từ API Recommendations
  List<MatchUser> _getConsolidatedUsers(List<MatchUser> apiUsers) {
    // Chỉ lấy người dùng thực tế từ Database, loại bỏ hoàn toàn việc tự động chèn mockdata
    final List<MatchUser> list = List.from(apiUsers);

    // 3. Áp dụng bộ lọc chuyên sâu
    var filtered = _filterCriteria.apply(list);

    // 4. Áp dụng thanh lọc nhanh (Quick Vibe Pills)
    switch (_selectedVibe) {
      case 'nearby':
        filtered = filtered.where((u) => (u.distanceKm ?? 2.0) <= 3.5).toList();
        break;
      case 'high_match':
        filtered = filtered.where((u) => u.compatibilityScore >= 80).toList();
        break;
      case 'binh_yen':
        filtered = filtered
            .where((u) => u.emotion.toLowerCase().contains('bình yên'))
            .toList();
        break;
      case 'lang_man':
        filtered = filtered
            .where((u) => u.emotion.toLowerCase().contains('lãng mạn'))
            .toList();
        break;
      case 'bi_an':
        filtered = filtered
            .where((u) => u.emotion.toLowerCase().contains('bí ẩn'))
            .toList();
        break;
      case 'chill':
        filtered = filtered
            .where((u) => u.emotion.toLowerCase().contains('chill'))
            .toList();
        break;
      case 'sau_lang':
        filtered = filtered
            .where((u) =>
                u.emotion.toLowerCase().contains('sâu lắng') ||
                u.tags?.any((t) =>
                    t.toLowerCase().contains('deeptalk') ||
                    t.toLowerCase().contains('đêm')) ==
                    true)
            .toList();
        break;
      case 'phan_khich':
        filtered = filtered
            .where((u) => u.emotion.toLowerCase().contains('phấn khích'))
            .toList();
        break;
      case 'all':
      default:
        break;
    }

    return filtered;
  }

  /// Thuật toán phân bổ tọa độ cực thiên văn theo khoảng cách thực tế (Polar Radar Coordinates)
  Offset _calculateNodePosition({
    required int index,
    required int total,
    required MatchUser user,
    required Offset center,
    required double radius,
    required double screenWidth,
    required double screenHeight,
  }) {
    final count = math.max(total, 5);
    final step = (2 * math.pi) / count;
    final angle = -math.pi / 3 + (index * step);

    // Phân bổ cự ly theo khoảng cách thực tế (0.5km - 10km) tương ứng 4 vòng radar
    double distRatio;
    if (user.distanceKm != null && user.distanceKm! > 0) {
      // 0.5km -> 0.28 (vòng 1); 10km -> 0.95 (vòng 4)
      distRatio = (user.distanceKm! / 10.0).clamp(0.28, 0.95);
    } else {
      // So le 3 tầng quỹ đạo chống chồng lấn
      final isOuter = (index % 3 == 2);
      final isMid = (index % 3 == 1);
      distRatio = isOuter ? 0.90 : (isMid ? 0.65 : 0.40);
    }
    final dist = distRatio * radius;

    final x = center.dx + dist * math.cos(angle);
    final y = center.dy + dist * math.sin(angle);

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;
    final topSafePadding = MediaQuery.paddingOf(context).top;
    final bottomSafePadding = MediaQuery.paddingOf(context).bottom;

    // Chiều cao thực tế của ExploreTopHeader (SafeArea.top + Title row + Vibe Pills row)
    final headerTotalHeight = topSafePadding + 114.0;
    final bottomSheetMargin = 100.0 + bottomSafePadding;
    const peekCardEstimatedHeight = 160.0;

    // Tâm Radar được căn chỉnh thông minh và cân đối tuyệt đối giữa Header và SoulPeekCard
    final availableSpaceTop = headerTotalHeight;
    final availableSpaceBottom = _selectedUser != null
        ? screenHeight - bottomSheetMargin - peekCardEstimatedHeight
        : screenHeight - bottomSheetMargin;

    final radarCenterY = availableSpaceTop + (availableSpaceBottom - availableSpaceTop) * 0.48;
    final radarCenter = Offset(screenWidth / 2, radarCenterY);

    // Bán kính radar co giãn thích ứng theo kích cỡ màn hình
    final maxAvailableRadius = math.min(
      (radarCenterY - availableSpaceTop) * 0.88,
      (availableSpaceBottom - radarCenterY) * 0.88,
    );
    final radarRadius = math.min(
      screenWidth * 0.42,
      math.max(120.0, maxAvailableRadius),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final users = _getConsolidatedUsers(state.matchedUsers);

          // Tự động chọn người đầu tiên nếu chưa chọn hoặc người được chọn không còn trong danh sách
          if (users.isNotEmpty) {
            if (_selectedUser == null || !users.any((u) => u.id == _selectedUser!.id)) {
              _selectedUser = users.first;
            }
          } else {
            _selectedUser = null;
          }

          // Tính toán tọa độ vị trí của selected user trên radar để vẽ tia laser
          Offset? selectedOffset;
          if (_selectedUser != null) {
            final idx = users.indexWhere((u) => u.id == _selectedUser!.id);
            if (idx != -1) {
              selectedOffset = _calculateNodePosition(
                index: idx,
                total: users.length,
                user: _selectedUser!,
                center: radarCenter,
                radius: radarRadius,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            }
          }

          return Stack(
            children: [
              // 1. Nền tinh vân cực quang phát sáng (Cosmic Ambient Glow)
              ExploreBackground(width: screenWidth, height: screenHeight),

              // 2. Chế độ hiển thị: Vòm Radar hoặc Lưới thẻ
              if (_isRadarView) ...[
                // Không gian Vòm Radar đa điểm cảm ứng (Pinch-to-Zoom & Pan như Google Maps)
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.55,
                  maxScale: 3.8,
                  boundaryMargin: EdgeInsets.all(screenWidth * 0.8),
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Canvas vẽ Vòm Radar thiên văn 360 độ (Animated) - Bọc RepaintBoundary
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _sweepController,
                              _waveController,
                              _shockwaveController,
                            ]),
                            builder: (context, child) {
                              final sweepRad = _sweepController.value * 2 * math.pi;
                              return CosmicRadarCanvas(
                                sweepAngle: sweepRad,
                                waveProgress: _waveController.value,
                                shockwaveProgress: _shockwaveController.value,
                                selectedTarget: selectedOffset,
                                center: radarCenter,
                                radius: radarRadius,
                              );
                            },
                          ),
                        ),

                        // Nút Tâm Radar: Bạn (Current User Core)
                        CosmicCenterNode(
                          center: radarCenter,
                          avatarUrl: _myAvatarUrl,
                        ),

                        // Các điểm tần số bay lơ lửng quanh quỹ đạo (Orbiting Soul Nodes)
                        ...users.asMap().entries.map((entry) {
                          final index = entry.key;
                          final user = entry.value;
                          final isSelected = _selectedUser?.id == user.id;

                          final nodePos = _calculateNodePosition(
                            index: index,
                            total: users.length,
                            user: user,
                            center: radarCenter,
                            radius: radarRadius,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                          );

                          return FloatingSoulNode(
                            key: ValueKey(user.id),
                            user: user,
                            position: nodePos,
                            isSelected: isSelected,
                            index: index,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedUser = user);
                            },
                            onDoubleTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(user: user),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Nút nổi "Quét 432Hz" (FAB Pulse) - Căn chỉnh Responsive chuẩn dưới Header
                Positioned(
                  top: headerTotalHeight + 12.0,
                  right: 16,
                  child: PulseActionButton(
                    animation: _pulseFabController,
                    onTap: _triggerSonarPulse,
                  ),
                ),

                // Cụm phím điều khiển Zoom kính mờ (+, -, Tỷ lệ Zoom, Tâm sóng) - Responsive
                Positioned(
                  top: headerTotalHeight + 68.0,
                  right: 16,
                  child: RadarControlsCluster(
                    currentScale: _currentScale,
                    onZoomIn: () => _zoomIn(radarCenter),
                    onZoomOut: () => _zoomOut(radarCenter),
                    onRecenter: _recenterRadar,
                  ),
                ),

                // Thẻ Kính Mờ "Soul Peek Sheet" hiển thị thông tin ở đáy màn hình
                // Đặt cao hơn thanh Bottom Navigation Bar để không bị nút Trái tim hồng che khuất
                if (_selectedUser != null)
                  Positioned(
                    bottom: bottomSheetMargin,
                    left: 0,
                    right: 0,
                    child: ResponsiveCenter(
                      maxWidth: 480,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.25),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: SoulPeekCard(
                          key: ValueKey(_selectedUser!.id),
                          user: _selectedUser!,
                          currentIndex: users.indexOf(_selectedUser!) + 1,
                          totalCount: users.length,
                          onChat: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MatchChatScreen(
                                  partnerName: _selectedUser!.displayName,
                                  partnerId: _selectedUser!.id,
                                ),
                              ),
                            );
                          },
                          onViewProfile: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserDetailScreen(
                                  user: _selectedUser!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // Chế độ Lưới Tần Số (Orbit Cards View) - Căn chỉnh Responsive chuẩn dưới Header
                Padding(
                  padding: EdgeInsets.only(
                    top: headerTotalHeight + 8.0,
                    bottom: bottomSheetMargin,
                  ),
                  child: ExploreGridView(
                    users: users,
                    onRefresh: () async {
                      context.read<HomeBloc>().add(
                            RefreshRecommendationsEvent(context),
                          );
                    },
                  ),
                ),
              ],

              // 3. Header Cực Quang & Bộ lọc (Fixed Top)
              ExploreTopHeader(
                isRadarView: _isRadarView,
                selectedVibe: _selectedVibe,
                filterCriteria: _filterCriteria,
                currentScale: _currentScale,
                onModeChanged: (isRadar) {
                  setState(() => _isRadarView = isRadar);
                },
                onVibeChanged: (vibe) {
                  setState(() => _selectedVibe = vibe);
                },
                onFilterTap: () => _openFilterModal(state.matchedUsers),
              ),
            ],
          );
        },
      ),
    );
  }
}