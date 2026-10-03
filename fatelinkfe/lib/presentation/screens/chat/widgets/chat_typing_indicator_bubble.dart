import 'package:flutter/material.dart';
import '../../../../presentation/widgets/typing_indicator.dart';

/// Bong bóng hiển thị Faye AI đang gõ phản hồi (ChatTypingIndicatorBubble)
class ChatTypingIndicatorBubble extends StatelessWidget {
  const ChatTypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
              ),
            ),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
              radius: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }
}
