import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../data/models/vibe_photo_item.dart';

class UserDetailVibeGallery extends StatelessWidget {
  final List<String> photos;
  final bool canViewIdentity;
  final bool isFaceLocked;

  const UserDetailVibeGallery({
    super.key,
    required this.photos,
    required this.canViewIdentity,
    required this.isFaceLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Góc tâm hồn (Vibes)',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            if (!canViewIdentity)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: Color(0xFFEC4899),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Khóa ảnh',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          canViewIdentity
              ? 'Khoảnh khắc cuộc sống và cảm xúc của đối phương:'
              : (isFaceLocked
                    ? '🔒 Người này đang bật tính năng Khóa diện mạo cá nhân.'
                    : '🔒 Thả tim kết nối cả hai bên để cùng mở khóa Góc tâm hồn & Diện mạo.'),
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            color: canViewIdentity
                ? const Color(0xFF64748B)
                : const Color(0xFFEC4899),
            fontWeight: canViewIdentity ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Hàng ảnh Vibe
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final raw = photos[index];
              final item = VibePhotoItem.fromRaw(raw);
              return Container(
                width: 105,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                        image: ImagePickerService.getImageProvider(
                          item.imageUrl,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      // Huy hiệu thời gian tự hủy góc dưới (nếu đã mở diện mạo)
                      if (canViewIdentity && !item.isExpired)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    item.remainingTimeFormatted,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Lớp Kính Mờ Blur nếu diện mạo bị khóa
                      if (!canViewIdentity)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
