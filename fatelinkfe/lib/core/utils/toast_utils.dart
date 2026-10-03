import 'package:flutter/material.dart';
import 'error_formatter.dart';

class ToastUtil {
  static OverlayEntry? _currentEntry;

  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      const Color(0xFF10B981), // Emerald
      Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    final cleanMessage = ErrorFormatter.format(message);
    _showToast(
      context,
      cleanMessage,
      const Color(0xFFF43F5E), // Rose
      Icons.error_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message,
      const Color(0xFF6366F1), // Brand Indigo
      Icons.info_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message,
      const Color(0xFFF59E0B), // Amber
      Icons.warning_rounded,
    );
  }

  static void _showToast(BuildContext context, String message, Color color, IconData icon) {
    try {
      _currentEntry?.remove();
      _currentEntry = null;
    } catch (_) {}

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        message: message,
        color: color,
        icon: icon,
        onDismiss: () {
          if (_currentEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
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
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Tự động đóng Toast sau 2.8 giây
    Future.delayed(const Duration(milliseconds: 2800), () {
      _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (!mounted || _isDismissed) return;
    _isDismissed = true;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding > 0 ? topPadding + 10 : 24,
      left: 20,
      right: 20,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! < -5) {
            _dismiss(); // Kéo lên để ẩn toast
          }
        },
        onTap: _dismiss,
        child: SlideTransition(
          position: _offsetAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.16),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
