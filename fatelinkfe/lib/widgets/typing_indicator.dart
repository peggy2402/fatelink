import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              // Tạo hiệu ứng nhấp nháy nối tiếp nhau cho mỗi chấm
              curve: Interval(
                0.2 * index,
                0.2 * index + 0.4,
                curve: Curves.easeInOut,
              ),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              '●',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        );
      }),
    );
  }
}
