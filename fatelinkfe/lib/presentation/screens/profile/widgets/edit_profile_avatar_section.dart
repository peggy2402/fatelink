import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';

class EditProfileAvatarSection extends StatelessWidget {
  final String avatarSource;
  final VoidCallback onPickAvatar;

  const EditProfileAvatarSection({
    super.key,
    required this.avatarSource,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: onPickAvatar,
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image(
                      image: ImagePickerService.getImageProvider(avatarSource),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const CircleAvatar(
                            radius: 46,
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(
                              Icons.person,
                              color: Color(0xFF6366F1),
                              size: 44,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onPickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: onPickAvatar,
            icon: const Icon(
              Icons.photo_library_outlined,
              size: 16,
              color: Color(0xFF6366F1),
            ),
            label: const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
