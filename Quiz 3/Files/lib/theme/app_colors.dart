import 'package:flutter/material.dart';

class AppColors {
  static const text = Color(0xFF1E1B4B);
  static const background = Color(0xFFF8F7FF);
  static const foreground = Color(0xFF1E1B4B);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF6D28D9);
  static const secondary = Color(0xFFEDE9FE);
  static const muted = Color(0xFFF3F0FF);
  static const mutedForeground = Color(0xFF7C6FAB);
  static const border = Color(0xFFE2DDFF);
  static const input = Color(0xFFF5F3FF);
  static const destructive = Color(0xFFDC2626);
  static const success = Color(0xFF059669);
  static const info = Color(0xFF2563EB);
  static const gradientStart = Color(0xFF6D28D9);
  static const gradientEnd = Color(0xFF8B5CF6);
  static const sidebar = Color(0xFF1E1535);
  static const sidebarText = Color(0xFFC4B5FD);
  static const sidebarBorder = Color(0xFF2D1F4A);
  static const radius = 12.0;

  static LinearGradient purpleGradient() {
    return const LinearGradient(
      colors: [gradientStart, gradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
