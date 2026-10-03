import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';

/// Thanh hiển thị Avatar sương mù và tiến trình tỏ tường tâm hồn (SoulMistAvatarBar):
/// - Avatar bị làm mờ bởi ImageFilter.blur theo _currentBlur
/// - Thanh tiến trình phần trăm rõ nét
class SoulMistAvatarBar extends StatelessWidget {
  final MatchUser partner;
  final double currentBlur;
  final bool isUnlockedForever;

  const SoulMistAvatarBar({
    super.key,
    required this.partner,
    required this.currentBlur,
    required this.isUnlockedForever,
  });

  @override
  Widget build(BuildContext context) {
    final unlockPercent = ((1.0 - (currentBlur / 18.0)) * 100).clamp(0, 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Avatar có hiệu ứng sương mù (Mist Blur)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlockedForever
                        ? const Color(0xFFFF2A6D)
                        : const Color(0xFF00F0FF),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: currentBlur, sigmaY: currentBlur),
                    child: partner.avatar != null && partner.avatar!.isNotEmpty
                        ? Image.network(partner.avatar!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF381559),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white70),
                            ),
                          ),
                  ),
                ),
              ),
              if (currentBlur > 2.0 && !isUnlockedForever)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.blur_on_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Tên & Tiến trình mở khóa sương mù
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isUnlockedForever ? partner.displayName : partner.anonymousName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${partner.emotion}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: unlockPercent / 100.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: isUnlockedForever
                              ? const Color(0xFFFF2A6D)
                              : const Color(0xFF00F0FF),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlockedForever ? 'Đã mở khóa' : '$unlockPercent%',
                      style: TextStyle(
                        color: isUnlockedForever
                            ? const Color(0xFFFF2A6D)
                            : const Color(0xFF00F0FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
