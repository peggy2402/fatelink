import 'package:flutter/material.dart';
import '../../../../data/models/chat_message.dart';

/// Bong bóng tin nhắn phòng chat Faye AI (ChatMessageBubble):
/// - Tin nhắn của Faye AI: Avatar kèm quầng sáng Cosmic Tri-Color Glow, thẻ tin nhắn kính mờ
///   trắng sữa sang trọng, viền phát sáng Indigo nhẹ, chữ màu slate sâu thẳm, huy hiệu AI ✨
/// - Tin nhắn của người dùng: Nền gradient hồng tím Fate Signature mềm mại, bo góc bất đối xứng thời thượng
/// - Định dạng thời gian rõ ràng, typography BeVietnamPro chuẩn mực
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
          // Avatar Faye AI ở phía trước tin nhắn bot kèm Cosmic Tri-Color Glow
          if (!isMe) ...[
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEC4899), // Pulse Pink
                    Color(0xFF8B5CF6), // Cosmic Violet
                    Color(0xFF00E5FF), // Electric Cyan
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)], // Fate Signature Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                            width: 1.0,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? const Color(0xFFEC4899).withValues(alpha: 0.3)
                            : const Color(0xFF6366F1).withValues(alpha: 0.08),
                        blurRadius: isMe ? 12 : 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Faye AI',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI ✨',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: isMe ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeString,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Color(0xFF94A3B8),
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
