import 'package:flutter/material.dart';
import '../../../../data/models/match_filter_criteria.dart';

/// Thanh bộ lọc nhanh ngang trên trang chủ (HomeQuickFilterBar):
/// - Tách rời logic hiển thị các chip lọc (Bộ lọc modal, Giới tính, Khu vực, Tuổi)
class HomeQuickFilterBar extends StatelessWidget {
  final MatchFilterCriteria filterCriteria;
  final VoidCallback onOpenFilterModal;
  final ValueChanged<MatchFilterCriteria> onCriteriaChanged;

  const HomeQuickFilterBar({
    super.key,
    required this.filterCriteria,
    required this.onOpenFilterModal,
    required this.onCriteriaChanged,
  });

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
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.white.withValues(alpha: 0.95),
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
  Widget build(BuildContext context) {
    final activeCount = filterCriteria.activeFilterCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 1. Nút mở Modal Bộ lọc chính
          GestureDetector(
            onTap: onOpenFilterModal,
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
            label: filterCriteria.gender == 'all'
                ? 'Giới tính'
                : (filterCriteria.gender == 'female' ? 'Nữ' : 'Nam'),
            isSelected: filterCriteria.gender != 'all',
            icon: Icons.wc_rounded,
            onTap: () {
              if (filterCriteria.gender == 'all') {
                onCriteriaChanged(filterCriteria.copyWith(gender: 'female'));
              } else if (filterCriteria.gender == 'female') {
                onCriteriaChanged(filterCriteria.copyWith(gender: 'male'));
              } else {
                onCriteriaChanged(filterCriteria.copyWith(gender: 'all'));
              }
            },
          ),

          const SizedBox(width: 8),

          // 3. Chip Lọc Toàn quốc / Gần bạn / Trong thành phố
          _buildFilterChipItem(
            label: filterCriteria.locationScope == 'nearby'
                ? 'Gần bạn (< 5km)'
                : (filterCriteria.locationScope == 'city'
                    ? 'Trong thành phố (< 25km)'
                    : 'Toàn quốc'),
            isSelected: filterCriteria.locationScope != 'all',
            icon: Icons.public_rounded,
            onTap: () {
              if (filterCriteria.locationScope == 'all') {
                onCriteriaChanged(filterCriteria.copyWith(locationScope: 'nearby'));
              } else if (filterCriteria.locationScope == 'nearby') {
                onCriteriaChanged(filterCriteria.copyWith(locationScope: 'city'));
              } else {
                onCriteriaChanged(filterCriteria.copyWith(locationScope: 'all'));
              }
            },
          ),

          const SizedBox(width: 8),

          // 4. Chip Lọc Độ tuổi
          _buildFilterChipItem(
            label: '${filterCriteria.ageRange.start.round()}-${filterCriteria.ageRange.end.round()} tuổi',
            isSelected: filterCriteria.ageRange.start > 18 || filterCriteria.ageRange.end < 45,
            icon: Icons.cake_rounded,
            onTap: onOpenFilterModal,
          ),
        ],
      ),
    );
  }
}
