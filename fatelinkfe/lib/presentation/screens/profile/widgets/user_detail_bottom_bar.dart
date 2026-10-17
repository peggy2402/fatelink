import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';

class UserDetailBottomBar extends StatelessWidget {
  final bool isFollowing;
  final bool isMutualFollow;
  final bool isWaveSent;
  final VoidCallback onToggleFollow;
  final VoidCallback onPrimaryAction;

  const UserDetailBottomBar({
    super.key,
    required this.isFollowing,
    required this.isMutualFollow,
    required this.isWaveSent,
    required this.onToggleFollow,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.paddingOf(context).bottom > 0
          ? MediaQuery.paddingOf(context).bottom + 10
          : 20,
      child: ResponsiveCenter(
        maxWidth: 500,
        child: Row(
          children: [
            // Nút Thả tim / Follow
            GestureDetector(
              onTap: onToggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isFollowing ? const Color(0xFFEC4899) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFollowing
                        ? const Color(0xFFEC4899)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFollowing
                          ? const Color(0xFFEC4899).withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isFollowing
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFollowing ? Colors.white : const Color(0xFFEC4899),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nút Hành Động Chính: "Trò chuyện ngay" (nếu đã kết nối) HOẶC "Gửi sóng 432Hz" (nếu chưa kết nối)
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isMutualFollow
                                  ? const Color(0xFF6366F1)
                                  : (isWaveSent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEC4899)))
                              .withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMutualFollow
                        ? const Color(0xFF6366F1)
                        : (isWaveSent
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEC4899)),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMutualFollow
                            ? Icons.chat_bubble_rounded
                            : (isWaveSent
                                  ? Icons.check_circle_rounded
                                  : Icons.bolt_rounded),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isMutualFollow
                              ? 'Trò chuyện ngay'
                              : (isWaveSent
                                    ? 'Đã phát sóng 432Hz'
                                    : 'Gửi sóng 432Hz'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
