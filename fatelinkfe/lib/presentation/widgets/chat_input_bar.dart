import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'chat_quick_chips.dart';

/// Thanh nhập liệu trò chuyện (ChatInputBar):
/// - Bám sát foot (đáy) điện thoại 100%, nền kính mờ trải dài qua vạch Home Indicator
/// - Responsive đa thiết bị (Phone, Tablet, Landscape xoay ngang)
/// - Tự động thích ứng giao diện Sáng / Tối (Light & Cosmic Dark)
/// - Cố định ở đáy màn hình với ràng buộc kích thước chuẩn xác, không bị bung lệch vị trí
/// - Hỗ trợ hàng chip trả lời nhanh (Quick Chips) linh hoạt bật/tắt
/// - Tùy biến gợi ý nhập (hintText), nút đính kèm (leading), nút mở rộng (trailing)
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final bool showQuickChips;
  final String hintText;
  final bool isDark;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPlusTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.showQuickChips = true,
    this.hintText = 'Nhắn tin cho Faye...',
    this.isDark = false,
    this.leading,
    this.trailing,
    this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;

    // Khi bàn phím mở: cách bàn phím 8px.
    // Khi bàn phím đóng: padding đáy theo safeBottom của thiết bị để nội dung không bị vạch Home Indicator che khuất,
    // trong khi màu nền của thanh input bar vẫn tràn xuống tận mép kính dưới cùng của điện thoại.
    final effectiveBottomPadding = bottomInset > 0
        ? 8.0
        : (safeBottom > 0 ? safeBottom + 4.0 : 12.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity, // Trải dài full viền ngang và chạm đáy foot điện thoại
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1122).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFF1E5ED),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: math.max(safeLeft, 12.0),
            right: math.max(safeRight, 12.0),
            top: 8.0,
            bottom: effectiveBottomPadding,
          ),
          child: Center(
            // Responsive: Giới hạn chiều rộng tối đa 720px trên Tablet/iPad nhưng nền vẫn trải full màn hình
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hàng chip gợi ý câu trả lời nhanh (Quick Reply Chips)
                  if (showQuickChips) ...[
                    ChatQuickChips(onSelectChip: onSubmitted),
                    const SizedBox(height: 6),
                  ],

                  // 2. Hàng nhập tin nhắn chính (Input Row)
                  Row(
                    children: [
                      // Nút leading tùy biến hoặc icon "+"
                      leading ??
                          IconButton(
                            onPressed: onPlusTap,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                              size: 26,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
                          ),
                      const SizedBox(width: 4),

                      // Ô nhập văn bản
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.grey.shade300,
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            controller: controller,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              hintText: hintText,
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              suffixIcon: Icon(
                                Icons.emoji_emotions_outlined,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                size: 20,
                              ),
                              suffixIconConstraints: const BoxConstraints(minWidth: 36),
                            ),
                            onSubmitted: onSubmitted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Nút Trailing tùy biến (nếu có)
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: 4),
                      ],

                      // Nút Gửi (Send Button)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            final text = controller.text.trim();
                            if (text.isNotEmpty) {
                              onSubmitted(text);
                              controller.clear();
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [Color(0xFFFF2A6D), Color(0xFFFF5E97)]
                                    : const [Color(0xFFF43F5E), Color(0xFFA855F7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFFFF2A6D) : const Color(0xFFF43F5E))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
