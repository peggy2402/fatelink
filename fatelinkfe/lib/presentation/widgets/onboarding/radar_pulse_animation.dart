import 'package:flutter/material.dart';

class RadarPulseAnimation extends StatefulWidget {
  final Widget centerChild;
  final double size;
  final Color pulseColor;

  const RadarPulseAnimation({
    super.key,
    required this.centerChild,
    this.size = 130,
    this.pulseColor = const Color(0xFFF43F5E),
  });

  @override
  State<RadarPulseAnimation> createState() => _RadarPulseAnimationState();
}

class _RadarPulseAnimationState extends State<RadarPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Ring 1
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              return Container(
                width: widget.size + (progress * 50),
                height: widget.size + (progress * 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.pulseColor.withValues(
                      alpha: ((1.0 - progress) * 0.45).clamp(0.0, 1.0),
                    ),
                    width: 2.0,
                  ),
                ),
              );
            },
          ),

          // Outer Pulse Ring 2 (Offset phase)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = (_controller.value + 0.5) % 1.0;
              return Container(
                width: widget.size + (progress * 35),
                height: widget.size + (progress * 35),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA855F7).withValues(
                      alpha: ((1.0 - progress) * 0.35).clamp(0.0, 1.0),
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),

          // Center Child Widget
          widget.centerChild,
        ],
      ),
    );
  }
}
