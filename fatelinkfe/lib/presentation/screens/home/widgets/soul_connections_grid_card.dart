import 'package:flutter/material.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../data/models/match_user.dart';

class SoulConnectionsGridCard extends StatelessWidget {
  final MatchUser user;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const SoulConnectionsGridCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final distance = user.distanceKm != null
        ? '${user.distanceKm} km'
        : '${((user.id.hashCode.abs() % 45) / 10.0 + 0.5).toStringAsFixed(1)} km';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Avatar trung tâm với hào quang mờ
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.20),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          AnonymousAvatarHelper.buildAvatar(
                            user: user,
                            size: 68,
                            showLockBadge: !user.canViewIdentity,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Thông tin tên, tuổi, giới tính & cự ly
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (!user.canViewIdentity) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: Color(0xFFEC4899),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${user.resolvedAge} tuổi • ${user.genderLabel}',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          Text(
                            distance,
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 3. Tần số cảm xúc pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tần số: ${user.moodIcon != null ? "${user.moodIcon} " : ""}${user.emotion}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),

                  // 4. Nút Hành Động: Trò chuyện (nếu đã kết nối) hoặc Gửi sóng 432Hz
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: user.isMutualFollow
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.isMutualFollow
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.bolt_rounded,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.isMutualFollow ? 'Trò chuyện' : 'Gửi sóng 432Hz',
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Huy hiệu % tương thích góc trên bên phải
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      '${user.compatibilityScore}%',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
