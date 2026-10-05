import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Biểu tượng Bông hoa pha lê tím MeyuFeel xuất hiện ở giữa màn hình chat
/// - Nằm sau nội dung đoạn chat (dạng Watermark biểu tượng tâm giao)
/// - Đã tách nền, mờ nhẹ nhàng (không làm che lấp chữ hay tin nhắn)
/// - Hiệu ứng nhấp nhô bồng bềnh (Floating bounce nhẹ nhàng)
/// - Bọc trong IgnorePointer để không cản trở lướt chat hay chạm tin nhắn
class MeyuFeelWatermarkLotus extends StatefulWidget {
  final double opacity;
  final double size;

  const MeyuFeelWatermarkLotus({
    super.key,
    this.opacity = 0.32,
    this.size = 280,
  });

  @override
  State<MeyuFeelWatermarkLotus> createState() => _MeyuFeelWatermarkLotusState();
}

class _MeyuFeelWatermarkLotusState extends State<MeyuFeelWatermarkLotus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Nhịp thở nhấp nhô nhẹ nhàng (Floating Bounce)
            final bounceOffset = 9.0 * math.sin(_controller.value * math.pi);
            final scaleFactor = 0.98 + 0.04 * _controller.value;

            return Transform.translate(
              offset: Offset(0, bounceOffset),
              child: Transform.scale(
                scale: scaleFactor,
                child: Opacity(
                  opacity: widget.opacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Quầng sáng tinh vân tím phát ra phía sau cánh hoa
                      Container(
                        width: widget.size * 0.75,
                        height: widget.size * 0.75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),

                      // Bông hoa sen pha lê tím tách nền
                      Image.asset(
                        'assets/images/meyufeel_lotus_cutout.jpg',
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.contain,
                        colorBlendMode: BlendMode.multiply,
                        color: const Color(0xFFF8FAFC),
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          'assets/images/meyufeel_crystal_lotus.jpg',
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
