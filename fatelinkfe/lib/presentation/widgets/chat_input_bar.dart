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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Nhắn tin cho Faye...',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.emoji_emotions_outlined,
                          color: Colors.grey.shade500),
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
