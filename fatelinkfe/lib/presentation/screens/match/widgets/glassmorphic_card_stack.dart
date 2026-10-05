import 'dart:io';
import 'package:flutter/material.dart';
import 'glassmorphic_image_viewer.dart';

/// Hiển thị danh sách nhiều ảnh dưới dạng "Modern Glassmorphic Card Stack UI"
/// - Các layer card ảnh xếp chồng lên nhau với độ xoay nghiêng nghệ thuật
/// - Góc bo tròn lớn 22px, bóng đổ mềm (soft shadows)
/// - Viền phản chiếu ánh sáng ngọc trai bồng bềnh
/// - Huy hiệu đếm số lượng ảnh
/// - Chạm vào để phóng to xem bộ sưu tập ảnh đầy đủ
class GlassmorphicCardStack extends StatelessWidget {
  final List<String> images;
  final bool isSentByMe;

  const GlassmorphicCardStack({
    super.key,
    required this.images,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Nếu chỉ có 1 ảnh: render thẻ ảnh đơn bo góc lớn
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => GlassmorphicImageViewer.show(context, images: images, initialIndex: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _buildImageItem(images.first, width: 230, height: 230),
        ),
      );
    }

    // Nếu có từ 2 ảnh trở lên: Render Modern Card Stack UI xếp lớp
    final displayCount = images.length;
    final topImage = images.first;
    final secondImage = images[1];
    final thirdImage = images.length > 2 ? images[2] : null;

    return GestureDetector(
      onTap: () => GlassmorphicImageViewer.show(context, images: images, initialIndex: 0),
      child: Container(
        width: 240,
        height: 250,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Layer 3 (Nếu có từ 3 ảnh trở lên): Card nền xoay nghiêng -4 độ
            if (thirdImage != null)
              Positioned(
                top: 6,
                right: isSentByMe ? 4 : null,
                left: isSentByMe ? null : 4,
                child: Transform.rotate(
                  angle: isSentByMe ? -0.07 : 0.07,
                  child: Container(
                    width: 215,
                    height: 215,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Opacity(
                        opacity: 0.65,
                        child: _buildImageItem(thirdImage, width: 215, height: 215),
                      ),
                    ),
                  ),
                ),
              ),

            // Layer 2: Card giữa xoay nghiêng 4 độ
            Positioned(
              top: 10,
              right: isSentByMe ? 10 : null,
              left: isSentByMe ? null : 10,
              child: Transform.rotate(
                angle: isSentByMe ? 0.05 : -0.05,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Opacity(
                      opacity: 0.85,
                      child: _buildImageItem(secondImage, width: 220, height: 220),
                    ),
                  ),
                ),
              ),
            ),

            // Layer 1 (Top Card): Card chính ở trên cùng thẳng thớm với viền sáng
            Positioned(
              top: 14,
              child: Container(
                width: 226,
                height: 226,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageItem(topImage, width: 226, height: 226),

                      // Huy hiệu đếm số ảnh góc phải dưới (Badge)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.collections_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+$displayCount',
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Colors.white,
                                  fontSize: 12,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(String path, {required double width, required double height}) {
    if (path.startsWith('file://')) {
      return Image.file(
        File(path.replaceFirst('file://', '')),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
      );
    }
    return Image.network(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
      ),
    );
  }
}
