import 'package:flutter/material.dart';

class FloatingAiBubble extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingAiBubble({super.key, required this.onTap});

  @override
  State<FloatingAiBubble> createState() => _FloatingAiBubbleState();
}

class _FloatingAiBubbleState extends State<FloatingAiBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showSpeechBubble = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Thi thoảng hiển thị bong bóng chat
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showSpeechBubble = true);
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _showSpeechBubble = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Vị trí phía trên BottomNavBar
      right: 24,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Bong bóng chat
            if (_showSpeechBubble)
              Positioned(
                right: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    'NGÀY HÔM NAY CỦA BẠN THẾ NÀO?',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Avatar AI
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0066FF), width: 3),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/avt_faye_ai.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
