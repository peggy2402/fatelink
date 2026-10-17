import 'package:flutter/material.dart';
import '../../../../data/models/match_filter_criteria.dart';

class SoulConnectionsFilterBar extends StatelessWidget {
  final MatchFilterCriteria criteria;
  final VoidCallback onOpenFilterModal;
  final VoidCallback onToggleGender;
  final VoidCallback onToggleScope;

  const SoulConnectionsFilterBar({
    super.key,
    required this.criteria,
    required this.onOpenFilterModal,
    required this.onToggleGender,
    required this.onToggleScope,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = criteria.activeFilterCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Nút mở Modal Bộ lọc chính
          GestureDetector(
            onTap: onOpenFilterModal,
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
            label: criteria.gender == 'all'
                ? 'Giới tính'
                : (criteria.gender == 'female' ? 'Nữ' : 'Nam'),
            isActive: criteria.gender != 'all',
            icon: Icons.wc_rounded,
            onTap: onToggleGender,
          ),

          const SizedBox(width: 8),

          // Chip lọc Khu vực nhanh
          _buildQuickFilterChip(
            label: criteria.locationScope == 'nearby'
                ? 'Gần bạn (< 5km)'
                : (criteria.locationScope == 'city'
                    ? 'Trong thành phố'
                    : 'Toàn quốc'),
            isActive: criteria.locationScope != 'all',
            icon: Icons.location_on_rounded,
            onTap: onToggleScope,
          ),

          const SizedBox(width: 8),

          // Chip lọc Độ tuổi nhanh
          _buildQuickFilterChip(
            label: '${criteria.ageRange.start.round()}-${criteria.ageRange.end.round()} tuổi',
            isActive: criteria.ageRange.start > 18 || criteria.ageRange.end < 45,
            icon: Icons.cake_rounded,
            onTap: onOpenFilterModal,
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
}
