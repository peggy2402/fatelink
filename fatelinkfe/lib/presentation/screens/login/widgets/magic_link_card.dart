import 'package:flutter/material.dart';

class MagicLinkCard extends StatelessWidget {
  const MagicLinkCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth <= 360;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E5EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB4D1).withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 38 : 44,
              height: isCompact ? 38 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFE1EE),
                    Colors.white.withValues(alpha: 0.86),
                  ],
                ),
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: isCompact ? 20 : 26,
                color: const Color(0xFFEF3D8B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không muốn nhập mật khẩu?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2F173D),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gửi link đăng nhập 1 lần qua email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 11.5 : 13,
                      color: const Color(0xFF768099),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: isCompact ? 24 : 28,
              color: const Color(0xFFEF3D8B),
            ),
          ],
        ),
      ),
    );
  }
}
