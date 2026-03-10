import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF3A7BC8);
  static const Color accent = Color(0xFFF5A623);

  // Light Theme
  static const Color lightText = Color(0xFF0D1B2A);
  static const Color lightTextSecondary = Color(0xFF5A7184);
  static const Color lightBackground = Color(0xFFF0F4F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDanger = Color(0xFFE53E3E);
  static const Color lightSuccess = Color(0xFF38A169);
  static const Color lightWarning = Color(0xFFDD6B20);
  static const Color lightInputBg = Color(0xFFF7FAFC);
  static const Color lightSkeleton = Color(0xFFE2E8F0);
  static const Color lightSkeletonShimmer = Color(0xFFF0F4F8);
  static const Color lightPlaceholder = Color(0xFFA0AEC0);

  // Dark Theme
  static const Color darkText = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF8899AA);
  static const Color darkBackground = Color(0xFF0D1B2A);
  static const Color darkCard = Color(0xFF1A2C3D);
  static const Color darkBorder = Color(0xFF2D3F50);
  static const Color darkDanger = Color(0xFFFC8181);
  static const Color darkSuccess = Color(0xFF68D391);
  static const Color darkWarning = Color(0xFFF6AD55);
  static const Color darkInputBg = Color(0xFF162435);
  static const Color darkSkeleton = Color(0xFF1A2C3D);
  static const Color darkSkeletonShimmer = Color(0xFF243A50);
  static const Color darkPlaceholder = Color(0xFF5A7184);
}

class AppThemeColors {
  final Color text;
  final Color textSecondary;
  final Color background;
  final Color card;
  final Color border;
  final Color danger;
  final Color success;
  final Color warning;
  final Color inputBg;
  final Color skeleton;
  final Color skeletonShimmer;
  final Color placeholder;
  final Color overlay;

  const AppThemeColors({
    required this.text,
    required this.textSecondary,
    required this.background,
    required this.card,
    required this.border,
    required this.danger,
    required this.success,
    required this.warning,
    required this.inputBg,
    required this.skeleton,
    required this.skeletonShimmer,
    required this.placeholder,
    required this.overlay,
  });

  static const AppThemeColors light = AppThemeColors(
    text: AppColors.lightText,
    textSecondary: AppColors.lightTextSecondary,
    background: AppColors.lightBackground,
    card: AppColors.lightCard,
    border: AppColors.lightBorder,
    danger: AppColors.lightDanger,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    inputBg: AppColors.lightInputBg,
    skeleton: AppColors.lightSkeleton,
    skeletonShimmer: AppColors.lightSkeletonShimmer,
    placeholder: AppColors.lightPlaceholder,
    overlay: Color(0x80000000),
  );

  static const AppThemeColors dark = AppThemeColors(
    text: AppColors.darkText,
    textSecondary: AppColors.darkTextSecondary,
    background: AppColors.darkBackground,
    card: AppColors.darkCard,
    border: AppColors.darkBorder,
    danger: AppColors.darkDanger,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    inputBg: AppColors.darkInputBg,
    skeleton: AppColors.darkSkeleton,
    skeletonShimmer: AppColors.darkSkeletonShimmer,
    placeholder: AppColors.darkPlaceholder,
    overlay: Color(0xB3000000),
  );
}
