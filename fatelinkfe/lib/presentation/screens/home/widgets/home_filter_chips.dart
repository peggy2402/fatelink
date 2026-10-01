import 'package:flutter/material.dart';

class HomeFilterChips extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HomeFilterChips({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static final List<Map<String, dynamic>> filters = [
    {'label': 'Tất cả', 'icon': Icons.all_inclusive_rounded},
    {'label': 'Cô đơn', 'icon': Icons.cloud_outlined},
    {'label': 'Phấn khích', 'icon': Icons.bolt_rounded},
    {'label': 'Deep talk', 'icon': Icons.chat_bubble_outline_rounded},
    {'label': 'Gần bạn', 'icon': Icons.near_me_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final item = filters[index];

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
