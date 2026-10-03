import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/match_filter_criteria.dart';

/// Thanh Header trên cùng màn hình Khám Phá:
/// - Tiêu đề & Trạng thái phát sóng thời gian thực
/// - Nút chuyển đổi chế độ xem (Vòm Radar 📡 / Lưới Thẻ 🎴)
/// - Nút mở bộ lọc chuyên sâu
/// - Thanh lọc nhanh cảm xúc (Quick Vibe Pills)
class ExploreTopHeader extends StatelessWidget {
  final bool isRadarView;
  final String selectedVibe;
  final MatchFilterCriteria filterCriteria;
  final double currentScale;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onVibeChanged;
  final VoidCallback onFilterTap;

  const ExploreTopHeader({
    super.key,
    required this.isRadarView,
    required this.selectedVibe,
    required this.filterCriteria,
    this.currentScale = 1.0,
    required this.onModeChanged,
    required this.onVibeChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = !filterCriteria.isDefault;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dòng 1: Tiêu đề + Chuyển chế độ (Radar / Grid) + Nút Bộ lọc
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tiêu đề & Trạng thái phát sóng
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                              ).createShader(bounds),
                              child: const Text(
                                'Khám phá',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isRadarView
                                      ? ((currentScale - 1.0).abs() > 0.08
                                          ? 'Bán kính ${(10.0 / currentScale).clamp(1.0, 50.0).toStringAsFixed(1)}km • Zoom ${currentScale.toStringAsFixed(1)}x'
                                          : 'Đang quét tần số • Bán kính 10km')
                                      : 'Danh sách tần số đồng điệu xung quanh',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Các nút hành động
                        Row(
                          children: [
                            // Nút chuyển chế độ Vòm Radar / Lưới Thẻ
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildModeButton(
                                    icon: Icons.radar_rounded,
                                    isActive: isRadarView,
                                    tooltip: 'Vòm Radar',
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onModeChanged(true);
                                    },
                                  ),
                                  _buildModeButton(
                                    icon: Icons.grid_view_rounded,
                                    isActive: !isRadarView,
                                    tooltip: 'Lưới thẻ',
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onModeChanged(false);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Nút Bộ Lọc Chuyên Sâu
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onFilterTap();
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: hasActiveFilter
                                      ? const Color(0xFF6366F1)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: hasActiveFilter
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: hasActiveFilter
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                    if (hasActiveFilter)
                                      Positioned(
                                        top: 7,
                                        right: 7,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEC4899),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Dòng 2: Thanh lọc nhanh
                    // Lưu ý: Các chức năng "Tất cả", "Gần tôi", "Tương hợp cao" KHÔNG có emoji
                    // CHỈ các mục CẢM XÚC mới hiển thị emoji!
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildVibePill('all', 'Tất cả'),
                          _buildVibePill('nearby', 'Gần tôi (<3km)'),
                          _buildVibePill('high_match', 'Tương hợp cao (≥80%)'),
                          _buildVibePill('binh_yen', '☕ Bình yên'),
                          _buildVibePill('lang_man', '💕 Lãng mạn'),
                          _buildVibePill('bi_an', '✨ Bí ẩn'),
                          _buildVibePill('chill', '🎧 Chill'),
                          _buildVibePill('sau_lang', '🌙 Sâu lắng'),
                          _buildVibePill('phan_khich', '☀️ Phấn khích'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildVibePill(String key, String label) {
    final isSelected = selectedVibe == key;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onVibeChanged(key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
