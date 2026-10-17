import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../data/models/vibe_photo_item.dart';

class ProfileVibeCorner extends StatelessWidget {
  final List<VibePhotoItem> vibes;
  final VoidCallback onAddPhotos;
  final ValueChanged<VibePhotoItem> onDeletePhoto;

  const ProfileVibeCorner({
    super.key,
    required this.vibes,
    required this.onAddPhotos,
    required this.onDeletePhoto,
  });

  void _showVibePreview(BuildContext context, VibePhotoItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image(
                    image: ImagePickerService.getImageProvider(item.imageUrl),
                    fit: BoxFit.contain,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Thanh thông tin thời hạn tự hủy ảnh & nút xóa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFF818CF8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tự hủy sau: ${item.remainingTimeFormatted}',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Thời hạn: ${item.durationLabel}',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDeletePhoto(item);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFF43F5E),
                      size: 16,
                    ),
                    label: const Text(
                      'Xóa ngay',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Color(0xFFF43F5E),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
                  'Góc tâm hồn (Vibe)',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            if (vibes.isNotEmpty)
              TextButton.icon(
                onPressed: onAddPhotos,
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 15,
                  color: Color(0xFF6366F1),
                ),
                label: const Text(
                  'Thêm ảnh',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Lưu giữ những khoảnh khắc không lộ mặt mang cảm xúc riêng.',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        if (vibes.isEmpty)
          InkWell(
            onTap: onAddPhotos,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF6366F1),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa có khoảnh khắc Vibe nào',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chạm vào đây để tải ảnh từ thư viện chia sẻ góc tâm hồn của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.blueGrey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: [
                ...vibes.map(
                  (item) => _buildVibeImageCard(context, item),
                ),
                _buildAddVibeCard(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVibeImageCard(BuildContext context, VibePhotoItem item) {
    return GestureDetector(
      onTap: () => _showVibePreview(context, item),
      child: Container(
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
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image(
                  image: ImagePickerService.getImageProvider(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Huy hiệu thời gian tự hủy góc dưới
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddVibeCard() {
    return InkWell(
      onTap: onAddPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 105,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: Color(0xFF94A3B8)),
            SizedBox(height: 4),
            Text(
              'Thêm Vibe',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
