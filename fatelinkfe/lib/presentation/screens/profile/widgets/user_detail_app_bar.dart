import 'package:flutter/material.dart';

class UserDetailAppBar extends StatelessWidget {
  final bool canViewIdentity;
  final VoidCallback onBack;
  final VoidCallback onOptionsTap;

  const UserDetailAppBar({
    super.key,
    required this.canViewIdentity,
    required this.onBack,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              canViewIdentity ? 'Hồ sơ người dùng' : 'Hồ sơ tâm hồn',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Nút trạng thái khóa diện mạo nhỏ ở góc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: canViewIdentity
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : const Color(0xFFEC4899).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  canViewIdentity
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  size: 13,
                  color: canViewIdentity
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEC4899),
                ),
                const SizedBox(width: 4),
                Text(
                  canViewIdentity ? 'Đã mở' : 'Đang khóa',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: canViewIdentity
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: onOptionsTap,
            tooltip: 'Tùy chọn',
          ),
        ],
      ),
    );
  }
}
