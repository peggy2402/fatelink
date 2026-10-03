import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/toast_utils.dart';
import '../utils/constants.dart';
import '../utils/secure_storage_helper.dart';
import '../../services/api_service.dart';

/// Dịch vụ quản lý chọn và xử lý hình ảnh cho Avatar và Góc tâm hồn (Vibes)
class ImagePickerService {
  ImagePickerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Hiển thị Modal Bottom Sheet cho phép người dùng chọn nguồn ảnh: Thư viện hoặc Camera
  static Future<String?> showImageSourceDialog(
    BuildContext context, {
    String title = 'Cập nhật hình ảnh',
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn nguồn ảnh từ thiết bị của bạn',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      ctx,
                      icon: Icons.photo_library_rounded,
                      label: 'Thư viện ảnh',
                      color: const Color(0xFF6366F1),
                      source: ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSourceOption(
                      ctx,
                      icon: Icons.camera_alt_rounded,
                      label: 'Chụp ảnh mới',
                      color: const Color(0xFFEC4899),
                      source: ImageSource.camera,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null && context.mounted) {
      return pickImage(context, source: source);
    }
    return null;
  }

  static Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chọn 1 hình ảnh từ camera hoặc thư viện
  static Future<String?> pickImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double maxWidth = 1024,
    double maxHeight = 1024,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (file == null) return null;

      // Nén ảnh sang base64 data URI để lưu trữ cục bộ và gửi backend
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = file.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mimeType;base64,$base64String';

      return dataUri;
    } catch (e) {
      if (context.mounted) {
        ToastUtil.showError(context, 'Không thể chọn ảnh: ${e.toString()}');
      }
      return null;
    }
  }

  /// Chọn nhiều ảnh cho album Góc tâm hồn (Vibes)
  static Future<List<String>> pickMultiVibeImages(
    BuildContext context, {
    int maxImages = 5,
  }) async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
        limit: maxImages,
      );

      final List<String> dataUris = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = file.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        dataUris.add('data:$mimeType;base64,$base64String');
      }
      return dataUris;
    } catch (e) {
      if (context.mounted) {
        ToastUtil.showError(context, 'Lỗi chọn ảnh: ${e.toString()}');
      }
      return [];
    }
  }

  /// Helper hiển thị ImageProvider tương thích cả URL mạng, Base64 Data URI và File cục bộ
  static ImageProvider getImageProvider(String source) {
    if (source.startsWith('data:image')) {
      final commaIndex = source.indexOf(',');
      if (commaIndex != -1) {
        final base64Data = source.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64Data));
      }
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    if (!kIsWeb && File(source).existsSync()) {
      return FileImage(File(source));
    }
    return NetworkImage(source);
  }

  /// Đẩy ảnh (Base64 hoặc File) lên Cloudinary thông qua Backend NestJS
  static Future<String?> uploadToCloudinary(
    BuildContext context,
    String imageSource, {
    String folder = 'fatelink/vibes',
    bool showLoading = false,
  }) async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      final url = '${AppConstants.baseUrl}/${AppConstants.uploadImage}';
      if (!context.mounted) return null;
      final response = await ApiService.post(
        url,
        context,
        body: {'image': imageSource, 'folder': folder},
        token: token,
        showLoading: showLoading,
      );

      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'];
        if (data != null && data['url'] != null) {
          return data['url'] as String;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
