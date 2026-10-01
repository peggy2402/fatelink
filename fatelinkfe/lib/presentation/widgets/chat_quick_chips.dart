import 'package:flutter/material.dart';

class ChatQuickChips extends StatelessWidget {
  final ValueChanged<String> onSelectChip;

  const ChatQuickChips({
    super.key,
    required this.onSelectChip,
  });

  static const List<Map<String, String>> _chips = [
    {'emoji': '🌙', 'text': 'Cần người tâm sự khuya'},
    {'emoji': '☕', 'text': 'Gợi ý cho tôi người hợp gu'},
    {'emoji': '🌧️', 'text': 'Hôm nay hơi mệt mỏi...'},
    {'emoji': '💡', 'text': 'Tần số cảm xúc của tôi là gì?'},
    {'emoji': '✨', 'text': 'Kể cho tôi một điều ấm áp'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _chips[index];
          return ActionChip(
            onPressed: () => onSelectChip(item['text']!),
            avatar: Text(item['emoji']!, style: const TextStyle(fontSize: 13)),
            label: Text(
              item['text']!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            elevation: 1,
            shadowColor: const Color(0xFFF43F5E).withValues(alpha: 0.2),
            side: BorderSide(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.25),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          );
        },
      ),
    );
  }
}
