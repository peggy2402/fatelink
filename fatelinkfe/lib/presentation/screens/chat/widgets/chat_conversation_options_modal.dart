import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal Tùy chọn Cuộc hội thoại khi nhấn giữ vào thẻ user
/// - Ghim hội thoại (Pin / Unpin)
/// - Bật / Tắt thông báo (Mute theo thời hạn: 1h, 4h, 1 ngày, vĩnh viễn)
/// - Xóa hội thoại
/// - Chặn người dùng
/// - Báo cáo vi phạm
/// - Hủy ghép đôi (Unmatch / Bỏ thích)
class ChatConversationOptionsModal extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool isPinned;
  final bool isMuted;
  final VoidCallback onTogglePin;
  final Function(Duration? duration) onMute;
  final VoidCallback onUnmute;
  final VoidCallback onDeleteConversation;
  final VoidCallback onBlockUser;
  final VoidCallback onReportUser;
  final VoidCallback onUnmatchUser;

  const ChatConversationOptionsModal({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isPinned,
    required this.isMuted,
    required this.onTogglePin,
    required this.onMute,
    required this.onUnmute,
    required this.onDeleteConversation,
    required this.onBlockUser,
    required this.onReportUser,
    required this.onUnmatchUser,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userName,
    String? userAvatar,
    required bool isPinned,
    required bool isMuted,
    required VoidCallback onTogglePin,
    required Function(Duration? duration) onMute,
    required VoidCallback onUnmute,
    required VoidCallback onDeleteConversation,
    required VoidCallback onBlockUser,
    required VoidCallback onReportUser,
    required VoidCallback onUnmatchUser,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChatConversationOptionsModal(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        isPinned: isPinned,
        isMuted: isMuted,
        onTogglePin: onTogglePin,
        onMute: onMute,
        onUnmute: onUnmute,
        onDeleteConversation: onDeleteConversation,
        onBlockUser: onBlockUser,
        onReportUser: onReportUser,
        onUnmatchUser: onUnmatchUser,
      ),
    );
  }

  void _showMuteDurationSheet(BuildContext context) {
    Navigator.pop(context); // Đóng modal chính
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tắt thông báo tin nhắn',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn sẽ không nhận được thông báo rung và chuông từ $userName.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              _buildDurationOption(
                ctx,
                title: 'Trong 1 giờ',
                duration: const Duration(hours: 1),
              ),
              _buildDurationOption(
                ctx,
                title: 'Trong 4 giờ',
                duration: const Duration(hours: 4),
              ),
              _buildDurationOption(
                ctx,
                title: 'Trong 1 ngày',
                duration: const Duration(days: 1),
              ),
              _buildDurationOption(
                ctx,
                title: 'Cho đến khi bật lại',
                duration: null, // vĩnh viễn
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(
    BuildContext context, {
    required String title,
    required Duration? duration,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const Icon(
        Icons.access_time_rounded,
        color: Color(0xFF6366F1),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
        size: 20,
      ),
      onTap: () {
        Navigator.pop(context);
        onMute(duration);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt modal
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),

            // Header người dùng
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEEF2FF),
                  backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
                      ? NetworkImage(userAvatar!)
                      : null,
                  child: userAvatar == null || userAvatar!.isEmpty
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tùy chọn tương tác cuộc hội thoại',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            const SizedBox(height: 8),

            // Nhóm 1: Ghim & Thông báo
            _buildActionTile(
              icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: isPinned ? 'Bỏ ghim hội thoại' : 'Ghim hội thoại',
              subtitle: isPinned ? 'Hạ vị trí ưu tiên' : 'Luôn đưa lên đầu danh sách',
              onTap: () {
                Navigator.pop(context);
                onTogglePin();
              },
            ),
            _buildActionTile(
              icon: isMuted
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              iconColor: isMuted ? const Color(0xFF10B981) : const Color(0xFF64748B),
              title: isMuted ? 'Bật thông báo' : 'Tắt thông báo',
              subtitle: isMuted ? 'Đang tắt thông báo' : 'Tắt rung và âm thanh',
              onTap: () {
                if (isMuted) {
                  Navigator.pop(context);
                  onUnmute();
                } else {
                  _showMuteDurationSheet(context);
                }
              },
            ),
            _buildActionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: const Color(0xFF64748B),
              title: 'Xóa hội thoại',
              subtitle: 'Xóa lịch sử tin nhắn khỏi danh sách',
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  title: 'Xóa cuộc trò chuyện?',
                  content:
                      'Toàn bộ tin nhắn với $userName sẽ bị xóa khỏi danh sách. Bạn không thể hoàn tác thao tác này.',
                  confirmText: 'Xóa hội thoại',
                  isDestructive: true,
                  onConfirm: onDeleteConversation,
                );
              },
            ),

            const SizedBox(height: 6),
            const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            const SizedBox(height: 6),

            // Nhóm 2: An toàn & Quan hệ (Chặn, Báo cáo, Hủy ghép đôi)
            _buildActionTile(
              icon: Icons.block_flipped,
              iconColor: const Color(0xFFEA580C),
              title: 'Chặn người này',
              subtitle: 'Người này sẽ không thể nhắn tin hay tìm thấy bạn',
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  title: 'Chặn $userName?',
                  content:
                      'Bạn và $userName sẽ không thể liên lạc, gọi điện hoặc nhìn thấy nhau trên FateLink nữa.',
                  confirmText: 'Chặn người dùng',
                  isDestructive: true,
                  onConfirm: onBlockUser,
                );
              },
            ),
            _buildActionTile(
              icon: Icons.report_problem_outlined,
              iconColor: const Color(0xFFD97706),
              title: 'Báo cáo vi phạm',
              subtitle: 'Báo cáo quấy rối, mạo danh hoặc nội dung xấu',
              onTap: () {
                Navigator.pop(context);
                onReportUser();
              },
            ),
            _buildActionTile(
              icon: Icons.heart_broken_rounded,
              iconColor: const Color(0xFFE11D48),
              title: 'Hủy ghép đôi (Unmatch / Bỏ thích)',
              subtitle: 'Ngắt kết nối định mệnh và kết thúc cuộc trò chuyện',
              isHighlightDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  title: 'Hủy ghép đôi với $userName?',
                  content:
                      'Hai bạn sẽ không còn xuất hiện trong danh sách tương thích của nhau và cuộc trò chuyện sẽ bị đóng lại.',
                  confirmText: 'Hủy ghép đôi',
                  isDestructive: true,
                  onConfirm: onUnmatchUser,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool isHighlightDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isHighlightDestructive
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1.5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xFFE11D48) : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
