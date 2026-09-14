import 'package:flutter/material.dart';

class AppColors {
  // Same as User App for consistency
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryGreen = Color(0xFF00695C);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color accentOrange = Color(0xFFFF9800);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryGreen],
  );

  static const Color background = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
}