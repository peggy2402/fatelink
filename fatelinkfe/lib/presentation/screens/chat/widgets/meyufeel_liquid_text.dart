import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget hiển thị chữ "MEYUFEEL" thuần Text, KHÔNG khung viền/badge/icon,
/// hiệu ứng nước dâng ngang (Horizontal Liquid Fill) chuẩn xác như ảnh mẫu SOULMATE:
/// - Bên trái ranh giới: Gradient hồng tím neon (#E11D48 -> #EC4899 -> #A855F7 -> #C084FC).
/// - Bên phải ranh giới: Màu xám than Slate-600 (#475569) đậm đà, đọc rõ 100%.
/// - Tối ưu hóa hiệu năng cao (StatelessWidget + RepaintBoundary): không chạy AnimationController lặp vô tận
///   trên từng dòng chat, giúp danh sách cuộn đạt chuẩn mượt mà 60-120 FPS.
class MeyuFeelLiquidText extends StatelessWidget {
  final double progress; // Từ 0.0 đến 1.0 (ví dụ 0.35 = 35%)
  final double fontSize;
  final String text;

  const MeyuFeelLiquidText({
    super.key,
    required this.progress,
    this.fontSize = 11.5,
    this.text = 'MEYUFEEL',
  });

  static const Color _unfilledColor = Color(0xFF475569); // Slate-600 đậm sắc sảo, đọc rõ 100%
  static const Color _cRose = Color(0xFFE11D48);
  static const Color _cPink = Color(0xFFEC4899);
  static const Color _cPurple = Color(0xFFA855F7);
  static const Color _cLavender = Color(0xFFC084FC);
  static const Color _cHighlight = Color(0xFFFDF2F8); // Ánh sáng mảnh mờ ngay mép nước

  Shader _createLiquidShader(Rect bounds) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Khi progress = 0: toàn chữ màu xám slate
    if (clampedProgress <= 0.0) {
      return const LinearGradient(
        colors: [_unfilledColor, _unfilledColor],
      ).createShader(bounds);
    }

    // Khi progress = 1: toàn chữ gradient hồng tím neon
    if (clampedProgress >= 1.0) {
      return const LinearGradient(
        colors: [_cRose, _cPink, _cPurple, _cLavender],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds);
    }

    final level = clampedProgress.clamp(0.01, 0.99);

    // Dải chuyển màu mềm (feather) 4% chiều ngang giữa phần đầy và phần xám
    const feather = 0.04;
    final crestStart = (level - feather * 0.5).clamp(0.0, 1.0);
    final crestEnd = (level + feather * 0.5).clamp(0.0, 1.0);

    final colors = <Color>[];
    final stops = <double>[];

    void addStop(Color color, double stop) {
      final safeStop = stops.isEmpty
          ? stop.clamp(0.0, 1.0)
          : math.max(stops.last, stop.clamp(0.0, 1.0));
      colors.add(color);
      stops.add(safeStop);
    }

    // Phần nước hồng tím neon phía trước
    addStop(_cRose, 0.0);
    addStop(_cPink, level * 0.4);
    addStop(_cPurple, level * 0.75);
    addStop(_cLavender, crestStart);

    // Điểm nhấn sáng rất mảnh và mờ tại ranh giới nước
    addStop(_cHighlight, level);

    // Chuyển mềm (feather) sang màu xám slate
    addStop(_unfilledColor, crestEnd);
    addStop(_unfilledColor, 1.0);

    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.8,
      color: Colors.white, // Để ShaderMask áp dải màu lên hình dạng chữ
    );

    return RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => _createLiquidShader(bounds),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: textStyle,
        ),
      ),
    );
  }
}
