import 'package:flutter/material.dart';

class AppColors {
  // Colors
  static const Color background = Color(0xFF001520);
  static const Color primary = Color(0xFFBD114A);
  static const Color secondary = Color(0xFFD75656);
  static const Color aiBubble = Color(0xFF0D47A1);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
  );
}
