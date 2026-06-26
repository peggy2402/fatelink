import 'package:flutter/material.dart';

class MagicLinkCard extends StatelessWidget {
  const MagicLinkCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0E5EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB4D1).withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFE1EE),
                    Colors.white.withValues(alpha: 0.86),
                  ],
                ),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 30,
                color: Color(0xFFEF3D8B),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Không muốn nhập mật khẩu?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F173D),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Gửi link đăng nhập 1 lần qua email',
                    style: TextStyle(fontSize: 14, color: Color(0xFF768099)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: Color(0xFFEF3D8B),
            ),
          ],
        ),
      ),
    );
  }
}
