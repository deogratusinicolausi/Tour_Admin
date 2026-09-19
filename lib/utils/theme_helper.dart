import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get pageBg => isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF212121);

  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF757575);

  Color get textMuted => isDark ? Colors.white54 : const Color(0xFFBDBDBD);

  Color get borderColor => isDark ? Colors.white24 : Colors.grey.shade300;

  Color get dividerColor => isDark ? Colors.white12 : Colors.grey.shade200;

  Color get inputBg => isDark ? const Color(0xFF2A2A2A) : Colors.white;

  Color get chipBg => isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
}