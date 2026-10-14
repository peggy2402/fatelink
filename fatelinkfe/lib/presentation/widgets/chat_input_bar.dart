import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_quick_chips.dart';

/// Thanh nhập liệu trò chuyện (ChatInputBar):
/// - Nền kính mờ Cosmic Glassmorphism sang trọng trải dài qua vạch Home Indicator
/// - Responsive đa thiết bị (Phone, Tablet, Landscape xoay ngang)
/// - Tự động thích ứng giao diện Sáng / Tối (Light & Cosmic Dark)
/// - Cố định ở đáy màn hình với ràng buộc kích thước chuẩn xác
/// - Hàng chip trả lời nhanh (Quick Chips) linh hoạt theo thời gian thực
/// - Nút bấm CTA chuẩn Rule 7 (triệt tiêu 100% vệt vuông mờ)
class ChatInputBar extends StatefulWidget {
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
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasTextNow = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasTextNow && mounted) {
      setState(() => _hasText = hasTextNow);
    }
  }

  void _onFocusChanged() {
    if (_isFocused != _focusNode.hasFocus && mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSubmitted(text);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;

    final effectiveBottomPadding = bottomInset > 0
        ? 8.0
        : (safeBottom > 0 ? safeBottom + 4.0 : 12.0);

    final isDark = widget.isDark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFF6366F1).withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.05),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hàng chip gợi ý câu trả lời nhanh theo ngữ cảnh thời gian
                  if (widget.showQuickChips) ...[
                    ChatQuickChips(
                      onSelectChip: (chipText) {
                        widget.onSubmitted(chipText);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 2. Hàng nhập tin nhắn chính (Input Row)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Nút leading tùy biến hoặc icon "+" chuẩn Cosmic
                      widget.leading ??
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(19),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onPlusTap?.call();
                                },
                                child: Center(
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: isDark ? Colors.white70 : const Color(0xFF6366F1),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(width: 8),

                      // Ô nhập văn bản Cosmic Aura
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isFocused
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.6)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFE2E8F0)),
                              width: _isFocused ? 1.5 : 1.0,
                            ),
                            boxShadow: _isFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 14.5,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              hintText: widget.hintText,
                              hintStyle: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 18,
                                ),
                              ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 38,
                                minHeight: 38,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nút Trailing tùy biến (nếu có)
                      if (widget.trailing != null) ...[
                        widget.trailing!,
                        const SizedBox(width: 6),
                      ],

                      // Nút Gửi (Send Button) - Chuẩn Rule 7 triệt tiêu vệt vuông mờ
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)], // Fate Signature Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: _hasText ? 0.45 : 0.25),
                              blurRadius: _hasText ? 10 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _handleSubmit,
                            child: const Center(
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
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
