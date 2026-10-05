import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Clipper để cắt dòng nước dâng ngang chính xác theo %
class _HorizontalLiquidClipper extends CustomClipper<Rect> {
  final double progress;

  _HorizontalLiquidClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, (size.width * progress).clamp(0.0, size.width), size.height);
  }

  @override
  bool shouldReclip(_HorizontalLiquidClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

/// Widget hiển thị chữ "MEYUFEEL" hoa văn mềm mại, SIÊU RÕ NÉT 100%,
/// kết hợp hiệu ứng DÒNG NƯỚC DÂNG THEO CHIỀU NGANG (Horizontal Liquid Wave Fill)
/// - Chữ "MEYUFEEL" hoa văn hoàng gia quý phái (Playfair Display ExtraBold Italic)
/// - ĐẢM BẢO 100% ĐỌC RÕ MỒN MỘT TỪNG KÝ TỰ:
///   + Lớp nền (Unfilled Base): Màu Slate-700 (#334155) đậm đà, sắc nét, tương phản tuyệt đối trên nền sáng
///   + Lớp nước dâng ngang (Liquid Fill): Màu gradient hồng tím neon dạ quang (#E11D48 -> #EC4899 -> #A855F7)
///   + Mép sóng nước (Wave Ripple Crest): Dải sáng trắng ánh hồng dao động nhấp nhô lấp lánh
///   + Bao bọc trong Capsule Pill viền phớt hồng tím thanh lịch đồng bộ với Badge Tuổi/Giới tính
class MeyuFeelLiquidText extends StatefulWidget {
  final double progress; // Từ 0.0 đến 1.0 (ví dụ 0.35 = 35%)
  final double fontSize;
  final String text; // Mặc định 'MEYUFEEL'

  const MeyuFeelLiquidText({
    super.key,
    required this.progress,
    this.fontSize = 11.5,
    this.text = 'MEYUFEEL',
  });

  @override
  State<MeyuFeelLiquidText> createState() => _MeyuFeelLiquidTextState();
}

class _MeyuFeelLiquidTextState extends State<MeyuFeelLiquidText>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  TextStyle _getTextStyle(Color color) {
    return GoogleFonts.playfairDisplay(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.9,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetProgress = widget.progress.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        // Gợn sóng lăn tăn ở ranh giới nước dâng theo chiều ngang
        final waveOffset = (targetProgress > 0 && targetProgress < 1.0)
            ? 0.02 * math.sin(_waveController.value * 2 * math.pi)
            : 0.0;
        final effectiveLevel = (targetProgress + waveOffset).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF1F2), // Phớt hồng phấn cực êm
                Color(0xFFFAF5FF), // Phớt tím lavender nhẹ
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFF472B6).withValues(alpha: 0.35),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.07),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon búp sen pha lê phát sáng nhỏ nhắn đồng điệu
              Padding(
                padding: const EdgeInsets.only(right: 3.5),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    '🪷',
                    style: TextStyle(
                      fontSize: widget.fontSize * 0.95,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Khối chữ "MEYUFEEL" xếp lớp nước dâng ngang
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Layer nền: Màu Slate-700 (#334155) ĐẬM NÉT 100% (Không bao giờ bị mờ hay chìm)
                  Text(
                    widget.text,
                    style: _getTextStyle(const Color(0xFF334155)),
                  ),

                  // 2. Layer nước dâng ngang: Màu hồng tím neon dạ quang rực rỡ
                  if (effectiveLevel > 0)
                    ClipRect(
                      clipper: _HorizontalLiquidClipper(effectiveLevel),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFE11D48), // Rose Red
                            Color(0xFFEC4899), // Pink Neon
                            Color(0xFFA855F7), // Purple Neon
                            Color(0xFFC084FC), // Lavender Glow
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          widget.text,
                          style: _getTextStyle(Colors.white),
                        ),
                      ),
                    ),

                  // 3. Mép sóng nước phát sáng lăn tăn (Wave Shimmer Crest)
                  if (effectiveLevel > 0.05 && effectiveLevel < 0.98)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final waveX = constraints.maxWidth * effectiveLevel;
                          return Stack(
                            children: [
                              Positioned(
                                left: (waveX - 2.5).clamp(0.0, constraints.maxWidth),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 3.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.95),
                                        const Color(0xFFF472B6).withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withValues(alpha: 0.7),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
