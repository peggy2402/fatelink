import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../data/models/match_user.dart';

/// Danh sách Avatar trực tuyến (ChatOnlineStories):
/// - Faye AI với viền phát sáng gradient Cosmic và huy hiệu sao
/// - Danh sách các người dùng thật đang hoạt động hoặc đã ghép đôi
class ChatOnlineStories extends StatelessWidget {
  final VoidCallback onFayeTap;
  final List<MatchUser> onlineUsers;
  final Function(MatchUser)? onUserTap;
  final VoidCallback? onDiscoverTap;

  const ChatOnlineStories({
    super.key,
    required this.onFayeTap,
    this.onlineUsers = const [],
    this.onUserTap,
    this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1 item cho Faye AI + các user thật + 1 nút Khám phá
    final hasUsers = onlineUsers.isNotEmpty;
    final totalCount = 1 + onlineUsers.length + (hasUsers ? 0 : 1);

    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          // Vị trí 0: Trợ lý Faye AI 24/7
          if (index == 0) {
            return _buildFayeItem();
          }

          // Vị trí các User thật
          final userIndex = index - 1;
          if (userIndex < onlineUsers.length) {
            final user = onlineUsers[userIndex];
            return _buildRealUserItem(user);
          }

          // Nút khám phá thêm khi chưa có nhiều bạn bè
          return _buildDiscoverActionItem(context);
        },
      ),
    );
  }

  Widget _buildFayeItem() {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: onFayeTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                  ),
                ),
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
            const SizedBox(height: 6),
            const Text(
              'Faye AI',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealUserItem(MatchUser user) {
    final canView = user.canViewIdentity;
    final displayName = canView ? user.name : user.anonymousName;
    final avatar = user.avatar;
    final hasValidAvatar = canView && avatar != null && avatar.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () => onUserTap?.call(user),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canView
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: canView
                        ? null
                        : Border.all(
                            color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: hasValidAvatar
                        ? ImagePickerService.getImageProvider(avatar)
                        : AssetImage(AnonymousAvatarHelper.getAnonymousAvatarAsset(user.id)),
                  ),
                ),
                // Chấm xanh Online góc dưới phải
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                // Huy hiệu Khóa Diện Mạo góc dưới trái nếu chưa kết đôi
                if (!canView)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                // Icon Cảm Xúc (Mood) góc trên phải
                if (user.moodIcon != null && user.moodIcon!.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(user.moodIcon!, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverActionItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: onDiscoverTap ?? () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tìm kiếm',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
