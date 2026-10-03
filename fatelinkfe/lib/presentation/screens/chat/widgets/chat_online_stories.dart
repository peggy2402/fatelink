import 'package:flutter/material.dart';

/// Danh sách Avatar trực tuyến (ChatOnlineStories):
/// - Faye AI với viền phát sáng gradient Cosmic và huy hiệu sao
/// - Danh sách các linh hồn đang hoạt động lân cận
class ChatOnlineStories extends StatelessWidget {
  final VoidCallback onFayeTap;

  const ChatOnlineStories({
    super.key,
    required this.onFayeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAvatarItem(
              name: 'Faye AI',
              imageUrl: 'assets/images/avt_faye_ai.png',
              isBot: true,
              onTap: onFayeTap,
            );
          }
          return _buildAvatarItem(
            name: 'Linh hồn ${index + 1}',
            imageUrl: 'assets/images/default_avatar.png',
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildAvatarItem({
    required String name,
    required String imageUrl,
    bool isBot = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: onTap,
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
                    gradient: isBot
                        ? const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: isBot ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: isBot
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(imageUrl),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB2),
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
                        color: Color(0xFF9C27B0),
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
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isBot ? Colors.grey.shade900 : Colors.grey.shade700,
                fontWeight: isBot ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
