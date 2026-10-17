import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/services/image_picker_service.dart';

class ProfileShareCardModal {
  static void show(
    BuildContext context, {
    required String name,
    required String handle,
    required String soulId,
    required String avatar,
  }) {
    final cleanHandle = SlugUtils.toCleanHandle(handle, fallbackSeed: soulId);
    final profileUrl = 'https://meyu.com/m/@$cleanHandle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final screenHeight = MediaQuery.sizeOf(bottomSheetContext).height;
        final bottomInset = MediaQuery.paddingOf(bottomSheetContext).bottom;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  bottomInset > 0 ? bottomInset + 16 : 32,
                ),
                child: ResponsiveCenter(
                  maxWidth: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thanh kéo
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Danh thiếp Meyu Soul',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Quét mã QR để đồng điệu tần số cùng tôi',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card danh thiếp
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header avatar + name
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFEC4899),
                                        Color(0xFF6366F1),
                                      ],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image(
                                      image: ImagePickerService.getImageProvider(avatar),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const CircleAvatar(
                                            backgroundColor: Color(0xFFE0E7FF),
                                            child: Icon(
                                              Icons.person,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '@$cleanHandle',
                                        style: const TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: 13,
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Mã QR 2D
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 2,
                                ),
                              ),
                              child: QrImageView(
                                data: profileUrl,
                                version: QrVersions.auto,
                                size: 160.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // URL Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'meyu.com/m/@$cleanHandle',
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nút Sao chép liên kết
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: profileUrl));
                            Navigator.pop(bottomSheetContext);
                            ToastUtil.showSuccess(
                              context,
                              'Đã sao chép liên kết: meyu.com/m/@$cleanHandle ✨',
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Sao chép liên kết danh thiếp',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
