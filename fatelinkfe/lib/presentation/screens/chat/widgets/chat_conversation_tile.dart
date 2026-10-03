import 'package:flutter/material.dart';

/// Item một cuộc trò chuyện trong danh sách chat (ChatConversationTile):
/// - Phân loại: Bot AI Faye, Tin nhắn hệ thống FateLink, hoặc Bạn bè thật (User-to-User)
/// - Avatar linh hoạt: Hỗ trợ URL Network, Asset hoặc Icon hệ thống
/// - Tên người gửi, tin nhắn cuối cùng thu gọn 1 dòng, thời gian và huy hiệu chưa đọc
class ChatConversationTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final IconData? systemIcon;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isBot;
  final bool isSystem;
  final VoidCallback onTap;

  const ChatConversationTile({
    super.key,
    required this.name,
    this.imageUrl,
    this.systemIcon,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isBot = false,
    this.isSystem = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: hasUnread
            ? const Color(0xFF6366F1).withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar / Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isBot
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: isBot
                        ? null
                        : Border.all(
                            color: isSystem
                                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                                : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                  ),
                  child: _buildAvatarContent(),
                ),
                if (!isSystem)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                if (isBot)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Tên & Tin nhắn cuối
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 15.5,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBot) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI BOT',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: Color(0xFF4F46E5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ] else if (isSystem) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HỆ THỐNG',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: Color(0xFF059669),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Thời gian & Badge Chưa đọc
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11.5,
                    color: hasUnread ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (isSystem) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFEEF2FF),
        child: Icon(
          systemIcon ?? Icons.notifications_active_rounded,
          color: const Color(0xFF6366F1),
          size: 26,
        ),
      );
    }

    final url = imageUrl;
    if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: NetworkImage(url),
      );
    }

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: AssetImage(url),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFEEF2FF),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }
}
