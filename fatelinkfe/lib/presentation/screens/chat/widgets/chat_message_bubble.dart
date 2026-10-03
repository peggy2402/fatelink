import 'package:flutter/material.dart';
import '../../../../data/models/chat_message.dart';

/// Bong bóng tin nhắn phòng chat Faye AI (ChatMessageBubble):
/// - Tin nhắn của Faye AI: Avatar tinh tế, bong bóng bo góc mềm mại nền xanh dịu / kính mờ
/// - Tin nhắn của người dùng: Nền gradient hồng tím chuẩn nhận diện thương hiệu FateLink
/// - Định dạng thời gian rõ ràng, khoảng đệm thoáng đãng
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar Faye AI ở phía trước tin nhắn bot
          if (!isMe) ...[
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
          ],

          // Khối nội dung tin nhắn
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.74,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFFFF2A6D), Color(0xFFFF5E97)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? const Color(0xFFFF2A6D) : const Color(0xFF2563EB))
                            .withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
