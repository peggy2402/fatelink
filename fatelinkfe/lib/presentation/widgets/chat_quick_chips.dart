import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickChipItem {
  final String emoji;
  final String text;

  const QuickChipItem({required this.emoji, required this.text});
}

class ChatQuickChips extends StatelessWidget {
  final ValueChanged<String> onSelectChip;
  final List<QuickChipItem>? customChips;
  final bool isDark;

  const ChatQuickChips({
    super.key,
    required this.onSelectChip,
    this.customChips,
    this.isDark = false,
  });

  /// Sinh danh sách chip gợi ý ngữ cảnh thông minh theo mốc thời gian thực trong ngày
  List<QuickChipItem> _resolveChips() {
    if (customChips != null && customChips!.isNotEmpty) {
      return customChips!;
    }

    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      // Đêm muộn (22h - 5h): Tâm sự khuya, chữa lành, lắng đọng
      return const [
        QuickChipItem(emoji: '🌙', text: 'Cần người tâm sự khuya'),
        QuickChipItem(emoji: '🎧', text: 'Gợi ý bản nhạc đêm nay'),
        QuickChipItem(emoji: '🌧️', text: 'Hôm nay hơi mệt mỏi...'),
        QuickChipItem(emoji: '✨', text: 'Kể cho tôi một điều ấm áp'),
        QuickChipItem(emoji: '💭', text: 'Làm sao để ngủ ngon hơn?'),
      ];
    } else if (hour >= 5 && hour < 12) {
      // Buổi sáng (5h - 12h): Khởi đầu ngày mới, năng lượng tích cực
      return const [
        QuickChipItem(emoji: '☕', text: 'Bắt đầu ngày mới nhiều năng lượng!'),
        QuickChipItem(emoji: '💡', text: 'Tần số cảm xúc hôm nay của tôi'),
        QuickChipItem(emoji: '✨', text: 'Gợi ý cho tôi người hợp gu'),
        QuickChipItem(emoji: '🎯', text: 'Hôm nay nên tập trung làm gì?'),
        QuickChipItem(emoji: '🌸', text: 'Một câu truyền cảm hứng'),
      ];
    } else if (hour >= 12 && hour < 18) {
      // Buổi chiều (12h - 18h): Thư giãn nhẹ, giải tỏa áp lực
      return const [
        QuickChipItem(emoji: '🍵', text: 'Buổi chiều nhẹ nhàng'),
        QuickChipItem(emoji: '☕', text: 'Gợi ý cho tôi người hợp gu'),
        QuickChipItem(emoji: '💡', text: 'Tần số cảm xúc của tôi là gì?'),
        QuickChipItem(emoji: '🌧️', text: 'Đang cần chút động lực...'),
        QuickChipItem(emoji: '✨', text: 'Kể cho tôi một câu chuyện vui'),
      ];
    } else {
      // Buổi tối (18h - 22h): Tan làm, chia sẻ cảm xúc sau ngày dài
      return const [
        QuickChipItem(emoji: '🌆', text: 'Tan làm rồi, trò chuyện chút nhé!'),
        QuickChipItem(emoji: '☕', text: 'Gợi ý cho tôi người hợp gu'),
        QuickChipItem(emoji: '💡', text: 'Tần số cảm xúc của tôi là gì?'),
        QuickChipItem(emoji: '🍲', text: 'Tối nay nên làm gì cho vui?'),
        QuickChipItem(emoji: '✨', text: 'Kể cho tôi một điều ấm áp'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = _resolveChips();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = chips[index];
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelectChip(item.text);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 13.5)),
                      const SizedBox(width: 6),
                      Text(
                        item.text,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
