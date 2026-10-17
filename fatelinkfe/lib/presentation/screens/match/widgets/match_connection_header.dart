import 'package:flutter/material.dart';

class MatchConnectionHeader extends StatelessWidget {
  final LinearGradient auraGradient;
  final Widget partnerAvatarWidget;
  final String partnerDisplayName;
  final String partnerHertz;
  final String? partnerBio;
  final VoidCallback onProfileTap;

  const MatchConnectionHeader({
    super.key,
    required this.auraGradient,
    required this.partnerAvatarWidget,
    required this.partnerDisplayName,
    required this.partnerHertz,
    this.partnerBio,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFF1E5ED),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar lớn
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: auraGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: partnerAvatarWidget,
              ),
            ),
            const SizedBox(height: 12),

            // Tên thật đối phương
            Text(
              partnerDisplayName,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Chip Kết nối định mệnh & Tần số
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF5F3FF),
                    Color(0xFFFDF2F8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 13,
                    color: Color(0xFFEC4899),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Đồng điệu định mệnh • $partnerHertz',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lời chúc se duyên
            Text(
              partnerBio != null && partnerBio!.isNotEmpty
                  ? '“$partnerBio”'
                  : 'Hai bạn đã tìm thấy nhau giữa triệu tần số vũ trụ.\nHãy cùng mở đầu một cuộc trò chuyện chân thành nhé! ✨',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),

            // Nút bấm xem Profile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    color: Color(0xFF6366F1),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Nhấn để xem toàn bộ hồ sơ',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
