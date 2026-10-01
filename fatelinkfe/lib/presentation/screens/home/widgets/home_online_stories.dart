import 'package:flutter/material.dart';
import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/core/utils/toast_utils.dart';

class HomeOnlineStories extends StatelessWidget {
  final String? currentUserAvatar;
  final String? currentUserMood;
  final String? currentUserMoodIcon;
  final String? currentUserFrequency;
  final List<MatchUser>? onlineUsers;
  final VoidCallback? onAddStory;
  final VoidCallback? onRetakeRadar;
  final Function(MatchUser)? onMatchUserTap;
  final Function(Map<String, String>)? onUserTap;

  const HomeOnlineStories({
    super.key,
    this.currentUserAvatar,
    this.currentUserMood,
    this.currentUserMoodIcon,
    this.currentUserFrequency,
    this.onlineUsers,
    this.onAddStory,
    this.onRetakeRadar,
    this.onMatchUserTap,
    this.onUserTap,
  });



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Text(
                'Tần số đang phát',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stories Row
        SizedBox(
          height: 108,
          child: Builder(
            builder: (context) {
              final hasRealUsers = onlineUsers != null && onlineUsers!.isNotEmpty;
              final count = hasRealUsers ? onlineUsers!.length + 1 : 2;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: count,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddStoryButton(context);
                  }
                  if (hasRealUsers) {
                    final user = onlineUsers![index - 1];
                    return _buildMatchUserStoryItem(context, user);
                  }
                  return _buildInviteFriendStoryItem(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    final bool hasActiveFrequency = currentUserMood != null && currentUserMood!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onRetakeRadar ?? onAddStory ??
            () {
              ToastUtil.showInfo(context, 'Tính năng đăng story tâm trạng đang mở thử nghiệm');
            },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveFrequency
                        ? const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasActiveFrequency
                        ? null
                        : Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                    boxShadow: hasActiveFrequency
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: (currentUserAvatar != null && currentUserAvatar!.isNotEmpty)
                        ? NetworkImage(currentUserAvatar!) as ImageProvider
                        : const AssetImage('assets/images/default_avatar.png'),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(hasActiveFrequency ? 2 : 3),
                  decoration: BoxDecoration(
                    color: hasActiveFrequency ? Colors.white : null,
                    gradient: hasActiveFrequency
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: hasActiveFrequency
                      ? Text(
                          currentUserMoodIcon ?? '✨',
                          style: const TextStyle(fontSize: 12),
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasActiveFrequency ? 'Bạn' : 'Tâm trạng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: hasActiveFrequency ? const Color(0xFF0F172A) : const Color(0xFF475569),
                fontWeight: hasActiveFrequency ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (hasActiveFrequency)
              Text(
                currentUserFrequency ?? 'Đang phát',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteFriendStoryItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onAddStory ?? onRetakeRadar,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mời bạn bè',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const Text(
              'Cùng phát sóng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchUserStoryItem(BuildContext context, MatchUser user) {
    final avatarUrl = user.avatar ??
        'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(user.name)}&backgroundColor=e0e7ff';
    final mood = user.moodIcon ?? _getEmotionIcon(user.emotion);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => onMatchUserTap?.call(user),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Pulse LED Energy Gradient Ring
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF3E8FF),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage('assets/images/default_avatar.png'),
                        ),
                      ),
                    ),
                  ),
                ),
                // Mood Emoji Badge
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 66,
              child: Text(
                user.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getEmotionIcon(String emotion) {
    final lower = emotion.toLowerCase();
    if (lower.contains('cô đơn') || lower.contains('buồn')) return '🌧️';
    if (lower.contains('phấn khích') || lower.contains('vui')) return '✨';
    if (lower.contains('deep') || lower.contains('suy')) return '☕';
    if (lower.contains('ấm áp') || lower.contains('yêu')) return '☀️';
    if (lower.contains('bình yên') || lower.contains('thảnh thơi')) return '🍃';
    if (lower.contains('indie') || lower.contains('nhạc')) return '🎧';
    if (lower.contains('cháy') || lower.contains('startup')) return '🔥';
    return '💫';
  }
}
