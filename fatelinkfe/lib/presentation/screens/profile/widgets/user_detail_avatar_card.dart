import 'package:flutter/material.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../data/models/match_user.dart';

class UserDetailAvatarCard extends StatelessWidget {
  final MatchUser user;
  final bool canViewIdentity;
  final String displayName;
  final String distance;
  final List<String> tags;

  const UserDetailAvatarCard({
    super.key,
    required this.user,
    required this.canViewIdentity,
    required this.displayName,
    required this.distance,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatar ??
        'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(user.name)}&backgroundColor=e0e7ff';
    final auraGradient = AnonymousAvatarHelper.getCosmicAuraGradient(user.id);
    final avatarBorderGradient = canViewIdentity
        ? const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : auraGradient;

    return Column(
      children: [
        // Avatar: Nếu canViewIdentity = false -> Hiệu ứng Kính Mờ (Blur) + Ổ Khóa
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Avatar Container with Gradient Border
              Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarBorderGradient,
                  boxShadow: [
                    BoxShadow(
                      color: avatarBorderGradient.colors.first.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image(
                    image: canViewIdentity
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : AssetImage(
                            AnonymousAvatarHelper.getAnonymousAvatarAsset(
                              user.id,
                            ),
                          ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFFE0E7FF),
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF6366F1),
                            size: 60,
                          ),
                        ),
                  ),
                ),
              ),

              // Mood icon ở góc trên bên phải (top-right) theo quy chuẩn UI/UX
              if (user.moodIcon != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      user.moodIcon!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

              // Huy hiệu ổ khóa ẩn danh ở góc dưới bên phải (bottom-right)
              if (!canViewIdentity)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: auraGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Name & Verified or Lock Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 6),
            if (canViewIdentity)
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF3B82F6),
                size: 20,
              )
            else
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFEC4899),
                  size: 14,
                ),
              ),
          ],
        ),

        // Chip thông tin Linh vật Vũ trụ thanh lịch
        if (!canViewIdentity) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.12),
                  const Color(0xFFEC4899).withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Linh vật: ${AnonymousAvatarHelper.getAnonymousPersonaName(user.id)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 6),

        // Distance & Status
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF64748B),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              distance,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Đang phát tần số',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tần số cảm xúc Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                color: Color(0xFF6366F1),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Tần số: ${user.moodIcon != null ? "${user.moodIcon} " : ""}${user.emotion}',
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: Color(0xFF6366F1),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Tags List (Gu sống)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: tags.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                t,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
