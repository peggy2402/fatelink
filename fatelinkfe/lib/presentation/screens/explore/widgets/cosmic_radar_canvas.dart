import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Canvas vẽ hệ thống Vòm Radar Thiên Văn 360 độ cao cấp:
/// - 4 Vòng cự ly có nhãn (1km, 3km, 5km, 10km)
/// - Trục tọa độ thiên văn & La bàn 4 phương
/// - Tia quét sonar 360 độ phát sáng (Rotating Sweep Beam)
/// - Sóng siêu âm lan tỏa liên tục (Expanding Sonar Waves)
/// - Tia laser cộng hưởng kết nối đến tâm hồn được chọn (Resonance Beam)
/// - Sóng xung kích phát ra khi bấm "Phát xung sóng" (Shockwave)
class CosmicRadarCanvas extends StatelessWidget {
  final double sweepAngle; // 0 .. 2*pi
  final double waveProgress; // 0 .. 1
  final double shockwaveProgress; // 0 .. 1
  final Offset? selectedTarget; // Tọa độ của user đang được chọn
  final Offset center;
  final double radius;

  const CosmicRadarCanvas({
    super.key,
    required this.sweepAngle,
    required this.waveProgress,
    this.shockwaveProgress = 0.0,
    this.selectedTarget,
    required this.center,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RadarPainter(
        sweepAngle: sweepAngle,
        waveProgress: waveProgress,
        shockwaveProgress: shockwaveProgress,
        selectedTarget: selectedTarget,
        center: center,
        radius: radius,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double waveProgress;
  final double shockwaveProgress;
  final Offset? selectedTarget;
  final Offset center;
  final double radius;

  _RadarPainter({
    required this.sweepAngle,
    required this.waveProgress,
    required this.shockwaveProgress,
    this.selectedTarget,
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;

    // 1. Vẽ các quầng phát sáng nền mờ nhẹ quanh tâm radar (Ambient Glow)
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.12),
          const Color(0xFFEC4899).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));
    canvas.drawCircle(center, radius * 1.1, ambientPaint);

    // 2. Vẽ 4 vòng cự ly thiên văn
    final ringMultipliers = [0.25, 0.50, 0.75, 1.00];
    final ringLabels = ['1 km', '3 km', '5 km', '10 km'];

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.18);

    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.22);

    for (int i = 0; i < ringMultipliers.length; i++) {
      final r = radius * ringMultipliers[i];
      // Vòng ngoài cùng và vòng thứ 2 vẽ nét đậm hơn
      if (i == 1 || i == 3) {
        canvas.drawCircle(center, r, dashedPaint);
      } else {
        canvas.drawCircle(center, r, ringPaint);
      }

      // Vẽ nhãn cự ly nhỏ xinh tinh tế ở góc 45 độ
      final labelAngle = math.pi / 4;
      final labelX = center.dx + r * math.cos(labelAngle) + 4;
      final labelY = center.dy + r * math.sin(labelAngle) - 10;

      final textSpan = TextSpan(
        text: ringLabels[i],
        style: TextStyle(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.85),
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'BeVietnamPro',
          letterSpacing: 0.3,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    // 3. Vẽ trục chữ thập thiên văn (N, E, S, W crosshairs)
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.5);

    // Đường ngang & dọc
    canvas.drawLine(
      Offset(center.dx - radius * 1.05, center.dy),
      Offset(center.dx + radius * 1.05, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 1.05),
      Offset(center.dx, center.dy + radius * 1.05),
      crossPaint,
    );

    // Ký hiệu 4 phương hướng thiên văn
    final compassMarkers = [
      {'label': 'B (N)', 'offset': Offset(center.dx, center.dy - radius * 1.08)},
      {'label': 'Đ (E)', 'offset': Offset(center.dx + radius * 1.08, center.dy)},
      {'label': 'N (S)', 'offset': Offset(center.dx, center.dy + radius * 1.08)},
      {'label': 'T (W)', 'offset': Offset(center.dx - radius * 1.08, center.dy)},
    ];

    for (final marker in compassMarkers) {
      final pos = marker['offset'] as Offset;
      final text = marker['label'] as String;
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xFF6366F1).withValues(alpha: 0.65),
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // 4. Vẽ sóng siêu âm nở dần ra ngoài (Expanding Sonar Ripples)
    for (int i = 0; i < 2; i++) {
      final progress = (waveProgress + i * 0.5) % 1.0;
      final rippleRadius = radius * progress;
      final rippleOpacity = (1.0 - progress) * 0.35;

      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * (1.0 - progress)
        ..color = const Color(0xFF00E5FF).withValues(alpha: rippleOpacity);

      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    // 5. Vẽ tia quét Radar Sonar 360 độ (Rotating Sweep Beam)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);

    final sweepSectorAngle = math.pi / 4; // 45 độ
    final sweepRect = Rect.fromCircle(center: Offset.zero, radius: radius);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -sweepSectorAngle,
        endAngle: 0.0,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
          const Color(0xFF6366F1).withValues(alpha: 0.08),
          const Color(0xFF00E5FF).withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(sweepRect);

    final sweepPath = Path()
      ..moveTo(0, 0)
      ..arcTo(sweepRect, -sweepSectorAngle, sweepSectorAngle, false)
      ..close();

    canvas.drawPath(sweepPath, sweepPaint);

    // Cạnh đầu tia quét phát sáng rực rỡ
    final frontEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF00E5FF), Colors.white],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, radius, 2));

    canvas.drawLine(Offset.zero, Offset(radius, 0), frontEdgePaint);
    canvas.restore();

    // 6. Vẽ tia Laser liên kết đến người dùng được chọn (Resonance Beam)
    if (selectedTarget != null) {
      final beamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFEC4899),
            const Color(0xFF6366F1),
            const Color(0xFF00E5FF),
          ],
        ).createShader(Rect.fromPoints(center, selectedTarget!));

      canvas.drawLine(center, selectedTarget!, beamPaint);

      // Hạt ánh sáng chuyển động dọc theo tia
      final photonProgress = waveProgress; // 0..1
      final photonPos = Offset.lerp(center, selectedTarget!, photonProgress)!;

      final photonGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(photonPos, 4.0, photonGlow);

      final photonCore = Paint()..color = Colors.white;
      canvas.drawCircle(photonPos, 2.0, photonCore);
    }

    // 7. Sóng xung kích khi bấm nút "Phát xung sóng" (Shockwave)
    if (shockwaveProgress > 0.0 && shockwaveProgress < 1.0) {
      final swRadius = radius * (0.1 + shockwaveProgress * 1.4);
      final swOpacity = (1.0 - shockwaveProgress) * 0.7;

      final shockwavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - shockwaveProgress)
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: swOpacity),
            const Color(0xFF00E5FF).withValues(alpha: swOpacity * 0.7),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: swRadius));

      canvas.drawCircle(center, swRadius, shockwavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.shockwaveProgress != shockwaveProgress ||
        oldDelegate.selectedTarget != selectedTarget ||
        oldDelegate.center != center ||
        oldDelegate.radius != radius;
  }
}
