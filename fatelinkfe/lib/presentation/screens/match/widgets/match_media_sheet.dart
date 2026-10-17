import 'package:flutter/material.dart';

class MatchMediaSheet extends StatelessWidget {
  final VoidCallback onPickMultiImages;
  final VoidCallback onPickCamera;
  final VoidCallback onShareLocation;
  final VoidCallback onVoiceNote;

  const MatchMediaSheet({
    super.key,
    required this.onPickMultiImages,
    required this.onPickCamera,
    required this.onShareLocation,
    required this.onVoiceNote,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPickMultiImages,
    required VoidCallback onPickCamera,
    required VoidCallback onShareLocation,
    required VoidCallback onVoiceNote,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MatchMediaSheet(
        onPickMultiImages: () {
          Navigator.pop(ctx);
          onPickMultiImages();
        },
        onPickCamera: () {
          Navigator.pop(ctx);
          onPickCamera();
        },
        onShareLocation: () {
          Navigator.pop(ctx);
          onShareLocation();
        },
        onVoiceNote: () {
          Navigator.pop(ctx);
          onVoiceNote();
        },
      ),
    );
  }

  Widget _buildMediaOptionItem({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chia sẻ tiện ích định mệnh',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMediaOptionItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Gửi nhiều ảnh',
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  onTap: onPickMultiImages,
                ),
                _buildMediaOptionItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Máy ảnh',
                  gradient: const [Color(0xFFEC4899), Color(0xFFD946EF)],
                  onTap: onPickCamera,
                ),
                _buildMediaOptionItem(
                  icon: Icons.location_on_rounded,
                  label: 'Vị trí',
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  onTap: onShareLocation,
                ),
                _buildMediaOptionItem(
                  icon: Icons.mic_rounded,
                  label: 'Ghi âm thoại',
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  onTap: onVoiceNote,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
