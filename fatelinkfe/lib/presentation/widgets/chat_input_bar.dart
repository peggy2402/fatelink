import 'dart:ui';
import 'package:flutter/material.dart';

import 'chat_quick_chips.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final bool showQuickChips;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.showQuickChips = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                ? 8.0
                : (MediaQuery.paddingOf(context).bottom + 6.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: const Border(
              top: BorderSide(color: Color(0xFFF1E5ED), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Quick Reply Chips for 1-tap responses
              if (showQuickChips) ...[
                ChatQuickChips(onSelectChip: onSubmitted),
                const SizedBox(height: 6),
              ],

              // 2. Input Row
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.grey.shade600,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300, width: 0.8),
                      ),
                      child: TextField(
                        controller: controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          hintText: 'Nhắn tin cho Faye...',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          suffixIconConstraints: const BoxConstraints(minWidth: 36),
                        ),
                        onSubmitted: onSubmitted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        onSubmitted(text);
                        controller.clear();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
