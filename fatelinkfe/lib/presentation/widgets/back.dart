import 'package:flutter/material.dart';

/// A custom back button widget designed with a consistent,
/// modern glassmorphism style for the application.
///
/// It features a circular, semi-transparent white background with a soft shadow,
/// containing a standard back arrow icon.
///
/// By default, tapping the button will pop the current route. This behavior
/// can be overridden by providing a custom [onPressed] callback.
class CustomBackButton extends StatelessWidget {
  /// An optional callback to override the default `Navigator.pop(context)` action.
  final VoidCallback? onPressed;

  const CustomBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade700, size: 20),
      ),
    );
  }
}