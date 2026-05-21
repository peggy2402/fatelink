  import 'package:flutter/material.dart';
  import 'dart:ui';

  class ChatInputBar extends StatelessWidget {
    final TextEditingController controller;
    final Function(String) onSubmitted;

    const ChatInputBar({
      super.key,
      required this.controller,
      required this.onSubmitted,
    });

    @override
    Widget build(BuildContext context) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                .copyWith(bottom: MediaQuery.of(context).padding.bottom + 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              border: Border(top: BorderSide(color: Colors.white, width: 1.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: Colors.grey.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      textAlignVertical: TextAlignVertical.center, // Ép chữ luôn căn giữa theo chiều dọc
                      decoration: InputDecoration(
                        isDense: true, // Thu gọn khoảng trắng thừa mặc định của TextField
                        contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10), // Giảm padding để hạ chiều cao
                        hintText: 'Nhắn tin cho Faye...',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.emoji_emotions_outlined,
                            color: Colors.grey.shade500),
                        suffixIconConstraints: const BoxConstraints(minWidth: 40), // Cố định vùng của icon tránh chèn ép chữ
                      ),
                      onSubmitted: onSubmitted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.mic_none, color: Colors.grey.shade600, size: 28),
              ],
            ),
          ),
        ),
      );
    }
  }
