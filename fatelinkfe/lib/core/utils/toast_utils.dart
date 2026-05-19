import 'package:flutter/material.dart';

class ToastUtil {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFF2E7D32), Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFFBD114A), Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFF0D47A1), Icons.info_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(context, message, const Color(0xFFFF9500), Icons.warning_amber_rounded);
  }

  static void _showToast(BuildContext context, String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        message: message,
        color: color,
        icon: icon,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _AnimatedToast extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _AnimatedToast({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Hiệu ứng trượt mượt mà từ trên cùng (-1.5) xuống giữa (0)
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Tự động đóng Toast sau 3 giây
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
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
      top: MediaQuery.of(context).padding.top + 16, // Hiển thị ngay dưới Status bar (tai thỏ)
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: widget.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Color(0xFF2F4F4F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
