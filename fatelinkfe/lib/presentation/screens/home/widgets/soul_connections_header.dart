import 'package:flutter/material.dart';

class SoulConnectionsHeader extends StatelessWidget {
  final int matchCount;
  final bool isSearchExpanded;
  final bool isGridView;
  final VoidCallback onBack;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleViewMode;

  const SoulConnectionsHeader({
    super.key,
    required this.matchCount,
    required this.isSearchExpanded,
    required this.isGridView,
    required this.onBack,
    required this.onToggleSearch,
    required this.onToggleViewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Nút quay lại
          GestureDetector(
            onTap: onBack,
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
                Text(
                  '$matchCount tần số đồng điệu phù hợp',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Nút Tìm kiếm
          GestureDetector(
            onTap: onToggleSearch,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSearchExpanded
                    ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSearchExpanded
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                size: 20,
                color: isSearchExpanded
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nút Chuyển đổi Grid / List
          GestureDetector(
            onTap: onToggleViewMode,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                size: 19,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
