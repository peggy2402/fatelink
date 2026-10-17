import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../data/models/vibe_photo_item.dart';

class EditProfileVibeManager extends StatelessWidget {
  final List<VibePhotoItem> vibePhotos;
  final VoidCallback onPickVibePhotos;
  final ValueChanged<int> onRemoveVibePhoto;

  const EditProfileVibeManager({
    super.key,
    required this.vibePhotos,
    required this.onPickVibePhotos,
    required this.onRemoveVibePhoto,
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
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Góc tâm hồn (Vibes)',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Text(
              '${vibePhotos.length}/6 ảnh',
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Lưu giữ những bức ảnh không lộ mặt thể hiện góc tâm hồn riêng của bạn.',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Nút thêm ảnh từ thư viện
              InkWell(
                onTap: onPickVibePhotos,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF6366F1),
                        size: 28,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thêm ảnh',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Danh sách ảnh Vibe đã chọn với huy hiệu đếm ngược tự hủy
              ...vibePhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image(
                            image: ImagePickerService.getImageProvider(
                              item.imageUrl,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Nút xóa ảnh góc trên phải
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveVibePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                      // Huy hiệu thời gian tự hủy góc dưới
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.68),
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
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
