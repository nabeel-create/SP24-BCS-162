import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppColors {
  const AppColors({
    required this.text,
    required this.tint,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.success,
    required this.warning,
    required this.info,
    required this.border,
    required this.input,
    required this.gradientStart,
    required this.gradientMid,
    required this.gradientEnd,
    required this.glassBg,
    required this.glassBorder,
    required this.blob1,
    required this.blob2,
    required this.blob3,
    required this.surfaceElevated,
    required this.overlay,
    required this.radius,
  });

  final Color text;
  final Color tint;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color success;
  final Color warning;
  final Color info;
  final Color border;
  final Color input;
  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;
  final Color glassBg;
  final Color glassBorder;
  final Color blob1;
  final Color blob2;
  final Color blob3;
  final Color surfaceElevated;
  final Color overlay;
  final double radius;
}

class AppPalette {
  static const double radius = 22;

  static const AppColors light = AppColors(
    text: Color(0xFF0A0A1F),
    tint: Color(0xFF7C3AED),
    background: Color(0xFFF4F0FF),
    foreground: Color(0xFF0A0A1F),
    card: Colors.white,
    cardForeground: Color(0xFF0A0A1F),
    primary: Color(0xFF7C3AED),
    primaryForeground: Colors.white,
    secondary: Color(0xFFEDE9FE),
    secondaryForeground: Color(0xFF0A0A1F),
    muted: Color(0xFFEDE9FE),
    mutedForeground: Color(0xFF6B6788),
    accent: Color(0xFFFBBF24),
    accentForeground: Color(0xFF0A0A1F),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Colors.white,
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF06B6D4),
    border: Color(0x267C3AED),
    input: Color(0x337C3AED),
    gradientStart: Color(0xFFA855F7),
    gradientMid: Color(0xFFEC4899),
    gradientEnd: Color(0xFFF97316),
    glassBg: Color(0x8CFFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    blob1: Color(0xFFC084FC),
    blob2: Color(0xFFF472B6),
    blob3: Color(0xFF67E8F9),
    surfaceElevated: Colors.white,
    overlay: Color(0x80101023),
    radius: radius,
  );

  static const AppColors dark = AppColors(
    text: Color(0xFFF8FAFC),
    tint: Color(0xFFA78BFA),
    background: Color(0xFF06030F),
    foreground: Color(0xFFF8FAFC),
    card: Color(0x8C1E163C),
    cardForeground: Color(0xFFF8FAFC),
    primary: Color(0xFFA78BFA),
    primaryForeground: Color(0xFF0A0A1F),
    secondary: Color(0x14FFFFFF),
    secondaryForeground: Color(0xFFF8FAFC),
    muted: Color(0x14FFFFFF),
    mutedForeground: Color(0xFFA8A3C4),
    accent: Color(0xFFFDE047),
    accentForeground: Color(0xFF0A0A1F),
    destructive: Color(0xFFFB7185),
    destructiveForeground: Color(0xFF0A0A1F),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF22D3EE),
    border: Color(0x1AFFFFFF),
    input: Color(0x1FFFFFFF),
    gradientStart: Color(0xFFA855F7),
    gradientMid: Color(0xFFEC4899),
    gradientEnd: Color(0xFFF97316),
    glassBg: Color(0x8C140E2D),
    glassBorder: Color(0x1FFFFFFF),
    blob1: Color(0xFF7C3AED),
    blob2: Color(0xFFEC4899),
    blob3: Color(0xFF06B6D4),
    surfaceElevated: Color(0xB31E163C),
    overlay: Color(0xB3000000),
    radius: radius,
  );
}

AppColors paletteOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}

ThemeData buildLightTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: AppPalette.light.primary,
      primary: AppPalette.light.primary,
      secondary: AppPalette.light.accent,
      error: AppPalette.light.destructive,
      surface: AppPalette.light.surfaceElevated,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.light.background,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.light.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radius),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppPalette.light.foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: AppPalette.light.mutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppPalette.dark.primary,
      primary: AppPalette.dark.primary,
      secondary: AppPalette.dark.accent,
      error: AppPalette.dark.destructive,
      surface: AppPalette.dark.surfaceElevated,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.dark.background,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.dark.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radius),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppPalette.dark.foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: AppPalette.dark.mutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
