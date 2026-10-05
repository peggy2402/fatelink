import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kho dữ liệu biểu cảm cảm xúc Cosmic
final Map<String, List<String>> kCosmicEmojiCategories = {
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

/// Khối hiển thị Emoji Panel dạng bàn phím inline (nằm dưới Chat Input Bar theo cấu trúc Stack / Column)
class CosmicEmojiPickerPanel extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final VoidCallback? onBackspace;
  final VoidCallback? onClose;
  final double height;

  const CosmicEmojiPickerPanel({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
    this.onClose,
    this.height = 280.0,
  });

  @override
  State<CosmicEmojiPickerPanel> createState() => _CosmicEmojiPickerPanelState();
}

class _CosmicEmojiPickerPanelState extends State<CosmicEmojiPickerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kCosmicEmojiCategories.keys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: widget.height + (bottomPadding > 0 ? bottomPadding : 10),
      padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Thanh điều hướng Tab Bar + Nút Backspace & Đóng
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF1F5F9),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: const Color(0xFF7C3AED),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF7C3AED),
                    indicatorWeight: 2.5,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: kCosmicEmojiCategories.keys.map((title) => Tab(text: title)).toList(),
                  ),
                ),
                if (widget.onBackspace != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 20),
                    color: const Color(0xFF64748B),
                    splashRadius: 20,
                    tooltip: 'Xóa lùi',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onBackspace!();
                    },
                  ),
                ],
                if (widget.onClose != null) ...[
                  IconButton(
                    icon: const Icon(Icons.keyboard_hide_rounded, size: 22),
                    color: const Color(0xFF64748B),
                    splashRadius: 20,
                    tooltip: 'Ẩn bảng emoji',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onClose!();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Lưới Emoji
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: kCosmicEmojiCategories.values.map((emojiList) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: emojiList.length,
                  itemBuilder: (context, index) {
                    final emoji = emojiList[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onEmojiSelected(emoji);
                      },
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
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
    );
  }
}

/// Modal Bottom Sheet dạng nổi (Fallback tương thích)
class CosmicEmojiPickerSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          CosmicEmojiPickerPanel(
            onEmojiSelected: (emoji) {
              onEmojiSelected(emoji);
              Navigator.of(context).pop();
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
