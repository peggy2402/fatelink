import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';

/// Thanh lọc bộ lọc danh sách trò chuyện (ChatFilterChips):
/// - Tách rời logic hiển thị các chip lọc phân loại cuộc hội thoại
class ChatFilterChips extends StatelessWidget {
  final List<MatchUser> allUsers;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const ChatFilterChips({
    super.key,
    required this.allUsers,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  Widget _buildChip(String key, String label) {
    final isSelected = selectedFilter == key;
    return GestureDetector(
      onTap: () => onFilterSelected(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = allUsers.where((u) => !u.isMutualFollow).length;
    final matchCount = allUsers.where((u) => u.isMutualFollow).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip('all', 'Tất cả'),
          const SizedBox(width: 8),
          _buildChip('matches', 'Bạn bè kết đôi 💕 ($matchCount)'),
          const SizedBox(width: 8),
          if (pendingCount > 0) ...[
            _buildChip('pending', 'Sóng chờ ⚡ ($pendingCount)'),
            const SizedBox(width: 8),
          ],
          _buildChip('ai', 'Trợ lý AI Faye'),
          const SizedBox(width: 8),
          _buildChip('unread', 'Chưa đọc'),
        ],
      ),
    );
  }
}
