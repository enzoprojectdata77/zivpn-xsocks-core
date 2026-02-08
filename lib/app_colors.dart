import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFF121218);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color card = Color(0xFF272736);
  static const Color logBackground = Color(0xFF0F0F12);

  // Opacity variants commonly used
  static Color get primaryLow => primary.withValues(alpha: 0.2);
  static Color get inputFill => Colors.black.withValues(alpha: 0.2);
}
