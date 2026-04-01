import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Import thư viện

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPlusTap;
  final bool isPopupOpen;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPlusTap,
    required this.isPopupOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
        ), // Margin nổi bồng bềnh
        decoration: BoxDecoration(
          color: const Color(0xFF001520), // Xanh navy đậm
          borderRadius: BorderRadius.circular(100), // Capsule shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Nút + với hiệu ứng xoay (AnimatedRotation)
            GestureDetector(
              onTap: onPlusTap,
              child: AnimatedRotation(
                turns: isPopupOpen ? 0.125 : 0.0, // Xoay 45 độ thành dấu X
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1E88E5,
                    ).withOpacity(0.25), // Xanh sáng nhẹ
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // TextField Pill-shaped
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.only(left: 16, right: 4),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1E88E5,
                  ).withOpacity(0.1), // Xanh nhạt hơn
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'chat_input_hint'.tr(),
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    // Nút Emoji
                    IconButton(
                      icon: const Icon(
                        Icons.sentiment_satisfied_alt,
                        color: Colors.white54,
                      ),
                      onPressed: () {}, // TODO: Xử lý mở Emoji Picker
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nút Mic / Send chuyển đổi tự động
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final isInputEmpty = value.text.trim().isEmpty;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: isInputEmpty
                      ? IconButton(
                          key: const ValueKey('mic'),
                          icon: const Icon(
                            Icons.mic_none,
                            color: Colors.white54,
                          ),
                          onPressed: () {}, // TODO: Xử lý thu âm Voice
                        )
                      : IconButton(
                          key: const ValueKey('send'),
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF1E88E5),
                          ),
                          onPressed: onSend,
                        ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
