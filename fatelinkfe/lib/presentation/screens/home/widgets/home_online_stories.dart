import 'package:flutter/material.dart';

class HomeOnlineStories extends StatelessWidget {
  final String? currentUserAvatar;
  final String? currentUserMood;
  final String? currentUserMoodIcon;
  final String? currentUserFrequency;
  final VoidCallback? onAddStory;
  final VoidCallback? onRetakeRadar;
  final Function(Map<String, String>)? onUserTap;

  const HomeOnlineStories({
    super.key,
    this.currentUserAvatar,
    this.currentUserMood,
    this.currentUserMoodIcon,
    this.currentUserFrequency,
    this.onAddStory,
    this.onRetakeRadar,
    this.onUserTap,
  });

  static final List<Map<String, String>> defaultOnlineUsers = [
    {
      'name': 'Luna',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Luna&backgroundColor=f3e8ff',
      'mood': '🌧️',
      'status': 'Cô đơn',
    },
    {
      'name': 'Alex',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Alex&backgroundColor=dbeafe',
      'mood': '🎧',
      'status': 'Nhạc Indie',
    },
    {
      'name': 'Mia',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Mia&backgroundColor=fce7f3',
      'mood': '✨',
      'status': 'Phấn khích',
    },
    {
      'name': 'Felix',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Felix&backgroundColor=e0e7ff',
      'mood': '☕',
      'status': 'Deep talk',
    },
    {
      'name': 'Chloe',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Chloe&backgroundColor=fef3c7',
      'mood': '🍃',
      'status': 'Bình yên',
    },
    {
      'name': 'Leo',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Leo&backgroundColor=dcfce7',
      'mood': '🔥',
      'status': 'Startup',
    },
    {
      'name': 'Sophie',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Sophie&backgroundColor=fae8ff',
      'mood': '🌙',
      'status': 'Thức muộn',
    },
  ];

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
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: defaultOnlineUsers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(context);
              }
              final user = defaultOnlineUsers[index - 1];
              return _buildUserStoryItem(context, user);
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng đăng story tâm trạng đang mở thử nghiệm'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
        child: Column(
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
            const SizedBox(height: 5),
            Text(
              hasActiveFrequency ? 'Bạn' : 'Tâm trạng',
              style: TextStyle(
                fontSize: 12,
                color: hasActiveFrequency ? const Color(0xFF0F172A) : const Color(0xFF475569),
                fontWeight: hasActiveFrequency ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (hasActiveFrequency)
              Text(
                currentUserFrequency ?? 'Đang phát',
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

  Widget _buildUserStoryItem(BuildContext context, Map<String, String> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => onUserTap?.call(user),
        child: Column(
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
                        user['avatar']!,
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
                      user['mood'] ?? '✨',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                user['name']!,
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
}
