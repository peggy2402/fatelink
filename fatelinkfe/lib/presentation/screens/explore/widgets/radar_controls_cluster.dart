import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cụm phím điều khiển Radar Thiên Văn (Zoom In, Zoom Out, Recenter & Zoom Badge):
/// - Lấy cảm hứng từ Google Maps & Zenly với phong cách Cosmic Glassmorphism
/// - Cho phép phóng to/thu nhỏ 1 chạm kèm rung phản hồi xúc giác Haptic
/// - Nút Recenter đưa Radar về tâm sóng của bạn
class RadarControlsCluster extends StatelessWidget {
  final double currentScale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const RadarControlsCluster({
    super.key,
    required this.currentScale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final isZoomed = (currentScale - 1.0).abs() > 0.08;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Nút Phóng to (+)
                _buildButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Phóng to radar',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onZoomIn();
                  },
                ),

                // 2. Huy hiệu hiển thị tỷ lệ Zoom (ví dụ: 1.0x, 1.5x, 2.0x)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isZoomed
                          ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${currentScale.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isZoomed
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                // 3. Nút Thu nhỏ (-)
                _buildButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Thu nhỏ radar',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onZoomOut();
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color(0xFFE2E8F0),
                  ),
                ),

                // 4. Nút Về tâm sóng (Recenter 🎯)
                _buildButton(
                  icon: Icons.my_location_rounded,
                  iconColor: isZoomed
                      ? const Color(0xFFEC4899)
                      : const Color(0xFF64748B),
                  backgroundColor: isZoomed
                      ? const Color(0xFFFDF2F8)
                      : Colors.transparent,
                  tooltip: 'Về tâm sóng của bạn',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onRecenter();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
