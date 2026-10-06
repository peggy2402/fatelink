import 'package:flutter/material.dart';
import 'meyufeel_liquid_text.dart';

/// Item một cuộc trò chuyện trong danh sách chat (ChatConversationTile):
/// - Phân loại: Bot AI Faye, Tin nhắn hệ thống FateLink, hoặc Bạn bè thật (User-to-User)
/// - Cấu trúc kiểu Messenger: Tên và tin nhắn là ưu tiên số 1, không bị ép cắt chữ
/// - Hàng 1: Tên (Expanded) + Thời gian
/// - Hàng 2: [Bạn bè kết đôi] Badge Tuổi/Giới tính + MEYUFEEL nước dâng ngang (FittedBox)
/// - Hàng 3: Tin nhắn cuối (Expanded) + Badge chưa đọc (chỉ hiện khi unreadCount > 0)
class ChatConversationTile extends StatelessWidget {
  // --- Kích thước và Typography chuẩn mực ---
  static const double kAvatarSize = 52.0;
  static const double kAvatarContentSpacing = 12.0;
  static const double kTileHorizontalPadding = 16.0;
  static const double kTileVerticalPadding = 10.0;
  static const double kTileMinHeight = 72.0;

  static const double kNameFontSize = 15.0;
  static const double kMessageFontSize = 13.0;
  static const double kTimeFontSize = 11.5;
  static const double kBadgeFontSize = 10.0;
  static const double kMeyuFeelFontSize = 11.5;

  final String name;
  final String? imageUrl;
  final IconData? systemIcon;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isBot;
  final bool isSystem;
  final bool isWaveRequest;
  final String? gender;
  final int? age;
  final double? meyuFeelProgress;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isPinned;
  final bool isMuted;

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
    this.isWaveRequest = false,
    this.gender,
    this.age,
    this.meyuFeelProgress,
    required this.onTap,
    this.onLongPress,
    this.isPinned = false,
    this.isMuted = false,
  });

  String _formatSnippet(String raw) {
    final isMe = raw.startsWith('Bạn: ');
    final content = isMe ? raw.substring(5).trim() : raw.trim();

    if (content.contains('[voice:') ||
        content.startsWith('🎙️') ||
        content.startsWith('{"type":"voice"') ||
        content.contains('"type":"voice"')) {
      return isMe ? 'Bạn: 🎙️ Tin nhắn thoại' : '🎙️ Tin nhắn thoại';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;
    final bool isFriendTile = !isBot &&
        !isSystem &&
        !isWaveRequest &&
        (gender != null || age != null || meyuFeelProgress != null);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 340;
    final displayTime = isNarrow && time == 'Vừa xong' ? 'Vừa' : time;

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.15,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kTileMinHeight),
              child: Container(
                color: isPinned
                    ? const Color(0xFF6366F1).withValues(alpha: 0.05)
                    : (hasUnread || isWaveRequest
                        ? const Color(0xFF6366F1).withValues(alpha: isWaveRequest ? 0.06 : 0.04)
                        : Colors.transparent),
                padding: const EdgeInsets.symmetric(
                  horizontal: kTileHorizontalPadding,
                  vertical: kTileVerticalPadding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Avatar 52dp kèm huy hiệu trạng thái
                    _buildAvatarWithBadge(),

                    const SizedBox(width: kAvatarContentSpacing),

                    // 2. Nội dung Column mở rộng
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng 1: [Tên (Flexible)] + [Huy hiệu tuổi/giới tính] + [Tag Bot/Hệ thống] + [Icon Ghim/Tắt Chuông + Thời gian]
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: kNameFontSize,
                                          fontWeight: hasUnread || isWaveRequest
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isFriendTile && (gender != null || age != null)) ...[
                                      const SizedBox(width: 6),
                                      _buildAgeGenderBadge(gender, age),
                                    ] else if (isWaveRequest) ...[
                                      const SizedBox(width: 6),
                                      _buildWaveTag(),
                                    ] else if (isBot) ...[
                                      const SizedBox(width: 6),
                                      _buildBotTag(),
                                    ] else if (isSystem) ...[
                                      const SizedBox(width: 6),
                                      _buildSystemTag(),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (isMuted) ...[
                                    const Icon(
                                      Icons.notifications_off_rounded,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],
                                  if (isPinned) ...[
                                    const Icon(
                                      Icons.push_pin_rounded,
                                      size: 13,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],
                                  Text(
                                    displayTime,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: kTimeFontSize,
                                      color: isWaveRequest
                                          ? const Color(0xFFEC4899)
                                          : (hasUnread
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFF94A3B8)),
                                      fontWeight: hasUnread || isWaveRequest
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Hàng 2: CHỈ hiển thị khi là bạn bè kết đôi có tiến trình MEYUFEEL
                          if (isFriendTile && meyuFeelProgress != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3.5, bottom: 2.5),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: MeyuFeelLiquidText(
                                  progress: meyuFeelProgress ?? 0.35,
                                  fontSize: kMeyuFeelFontSize,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 3),

                          // Hàng cuối: [Tin nhắn cuối (Expanded)] + [Badge chưa đọc chỉ hiện khi unreadCount > 0]
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatSnippet(lastMessage),
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: kMessageFontSize,
                                    fontWeight: hasUnread || isWaveRequest
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: hasUnread || isWaveRequest
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isWaveRequest) ...[
                                const SizedBox(width: 8),
                                _buildWaveBadge(),
                              ] else if (hasUnread) ...[
                                const SizedBox(width: 8),
                                _buildUnreadBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  // --- CÁC WIDGET PHỤ TRỢ ---

  Widget _buildAvatarWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: kAvatarSize,
          height: kAvatarSize,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isBot || isWaveRequest
                ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: isBot || isWaveRequest
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
        if (isWaveRequest)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 9,
              ),
            ),
          )
        else if (!isSystem)
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
          )
        else if (isWaveRequest)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    if (isWaveRequest && (imageUrl == null || imageUrl!.isEmpty)) {
      return const CircleAvatar(
        radius: kAvatarSize / 2,
        backgroundColor: Color(0xFFFDF2F8),
        child: Icon(
          Icons.sensors_rounded,
          color: Color(0xFFEC4899),
          size: 24,
        ),
      );
    }

    if (isSystem) {
      return CircleAvatar(
        radius: kAvatarSize / 2,
        backgroundColor: const Color(0xFFEEF2FF),
        child: Icon(
          systemIcon ?? Icons.notifications_active_rounded,
          color: const Color(0xFF6366F1),
          size: 24,
        ),
      );
    }

    final url = imageUrl;
    if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
      return CircleAvatar(
        radius: kAvatarSize / 2,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: NetworkImage(url),
      );
    }

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: kAvatarSize / 2,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: AssetImage(url),
      );
    }

    return CircleAvatar(
      radius: kAvatarSize / 2,
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

  Widget _buildWaveTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'SÓNG 432Hz',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBotTag() {
    return Container(
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
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSystemTag() {
    return Container(
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
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAgeGenderBadge(String? gender, int? age) {
    final isFemale = gender == 'female' || (gender == null);
    final effectiveAge = age ?? 19;
    final badgeColor = isFemale ? const Color(0xFFF43F5E) : const Color(0xFF3B82F6);
    final bgColor = isFemale ? const Color(0xFFFFF1F2) : const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isFemale ? '♀' : '♂',
            style: TextStyle(
              fontSize: kBadgeFontSize,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 1.5),
          Text(
            '$effectiveAge',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        unreadCount > 1 ? '$unreadCount sóng' : 'CHỜ ĐÓN',
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildUnreadBadge() {
    final text = unreadCount > 99
        ? '99+'
        : (unreadCount > 9 ? '9+' : '$unreadCount');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2A6D), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
