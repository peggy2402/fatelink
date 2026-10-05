import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bảng chọn Emoji phong cách Modern Glassmorphism
/// Giải quyết vấn đề 4: Cung cấp kho biểu cảm phong phú theo chủ đề cảm xúc, tình yêu, vũ trụ,
/// chèn mượt mà vào ô chat thay vì chỉ một icon khô khan.
class CosmicEmojiPickerSheet extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const CosmicEmojiPickerSheet({
    super.key,
    required this.onEmojiSelected,
  });

  static void show(
    BuildContext context, {
    required Function(String emoji) onEmojiSelected,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CosmicEmojiPickerSheet(onEmojiSelected: onEmojiSelected),
    );
  }

  @override
  State<CosmicEmojiPickerSheet> createState() => _CosmicEmojiPickerSheetState();
}

class _CosmicEmojiPickerSheetState extends State<CosmicEmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<String>> _categories = {
    'Yêu thương': [
      '❤️', '💖', '💘', '💝', '💞', '💕', '💌', '🥰', '😍', '😘',
      '😻', '🌹', '🌷', '💐', '🫶', '👩‍❤️‍👨', '💍', '🎁', '🍫', '🍷',
      '💓', '💗', '🤍', '💜', '💙', '🤎', '🖤', '🫂', '🕊️', '✨',
    ],
    'Cảm xúc': [
      '😊', '😂', '🤣', '🥺', '🥹', '😭', '😋', '😜', '😎', '🥳',
      '🤩', '🤗', '😇', '🤭', '😏', '🤤', '🫠', '🤧', '🤪', '😉',
      '😁', '😃', '😄', '😆', '☺️', '🙂', '😌', '😚', '😙', '😋',
    ],
    'Sâu lắng': [
      '😔', '😴', '🤔', '🤫', '🙄', '🤯', '😤', '🫣', '😮', '😯',
      '😲', '😳', '😬', '😮‍💨', '😪', '🤒', '🤕', '🤝', '🙏', '👏',
      '👍', '👎', '✌️', '🤞', '🤙', '👋', '👀', '🫦', '🧠', '🫀',
    ],
    'Vũ trụ': [
      '🔮', '🌌', '🪐', '⭐', '🌟', '💫', '⚡', '🌙', '☀️', '🌕',
      '💎', '🪷', '🦋', '🌈', '🔥', '☄️', '🛸', '🚀', '🕯️', '🪄',
      '🍀', '🍁', '🌊', '❄️', '🌸', '🌼', '🌻', '🍃', '🕊️', '🧸',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.keys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: 340,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Thanh kéo
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),

            // Tab bar các chủ đề emoji
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF7C3AED),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: _categories.keys.map((title) => Tab(text: title)).toList(),
            ),

            // Danh sách icon theo tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.values.map((emojiList) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: emojiList.length,
                    itemBuilder: (context, index) {
                      final emoji = emojiList[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onEmojiSelected(emoji);
                        },
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 27),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
