import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:fatelinkfe/widgets/chat_input_bar.dart';
import 'package:fatelinkfe/widgets/floating_ai_bubble.dart';

class MatchChatScreen extends StatefulWidget {
  final String partnerName;

  const MatchChatScreen({super.key, required this.partnerName});

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _chatController = TextEditingController();

  void _onAiSuggestionTap() {
    // Hiển thị BottomSheet gợi ý câu chat từ AI
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/avt_faye_ai.png',
                    ),
                    radius: 16,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Faye gợi ý mở lời:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSuggestionChip(
                'Chào cậu, hôm nay của cậu có mệt lắm không?',
              ),
              _buildSuggestionChip(
                'Faye bảo tần số của mình khá hợp nhau, cậu có thích ngắm mưa không?',
              ),
              _buildSuggestionChip(
                'Hi ${widget.partnerName}, cậu có đang nghe bài hát nào hay không share mình với?',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _chatController.text = text;
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.05),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.partnerName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          // ... List view tin nhắn sẽ nằm ở đây (Tạm thời để trống) ...

          // Chat Input Bar ở dưới cùng
          Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: _chatController,
              onSend: () {
                _chatController.clear();
              },
              onPlusTap: () {},
              isPopupOpen: false,
            ),
          ),

          // Nút AI Bong bóng trôi nổi
          FloatingAiBubble(
            onTap: _onAiSuggestionTap,
            hasNotification: true, // Chấm đỏ để user biết có thể bấm vào nhờ AI
          ),
        ],
      ),
    );
  }
}
