import 'package:flutter/material.dart';

class AppPalette {
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
  final Color border;
  final Color input;
  final Color underweight;
  final Color normal;
  final Color overweight;
  final Color obese;
  final Color cardBorder;
  final Color male;
  final Color female;

  const AppPalette({
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
    required this.border,
    required this.input,
    required this.underweight,
    required this.normal,
    required this.overweight,
    required this.obese,
    required this.cardBorder,
    required this.male,
    required this.female,
  });

  static const double radius = 20.0;

  static AppPalette get light => const AppPalette(
        text: Color(0xFF0A0015),
        tint: Color(0xFF7C3AED),
        background: Color(0xFFF8F5FF),
        foreground: Color(0xFF0A0015),
        card: Color(0xFFFFFFFF),
        cardForeground: Color(0xFF0A0015),
        primary: Color(0xFF7C3AED),
        primaryForeground: Color(0xFFFFFFFF),
        secondary: Color(0xFFEDE9FE),
        secondaryForeground: Color(0xFF4C1D95),
        muted: Color(0xFFF0EDF8),
        mutedForeground: Color(0xFF8B7DBA),
        accent: Color(0xFFDDD6FE),
        accentForeground: Color(0xFF5B21B6),
        destructive: Color(0xFFEF4444),
        destructiveForeground: Color(0xFFFFFFFF),
        border: Color(0xFFEBE5FF),
        input: Color(0xFFE4DCF7),
        underweight: Color(0xFF60A5FA),
        normal: Color(0xFF34D399),
        overweight: Color(0xFFFBBF24),
        obese: Color(0xFFF87171),
        cardBorder: Color(0x1A7C3AED),
        male: Color(0xFF4F46E5),
        female: Color(0xFFDB2777),
      );

  static AppPalette get dark => const AppPalette(
        text: Color(0xFFF0EEFF),
        tint: Color(0xFFC084FC),
        background: Color(0xFF07050F),
        foreground: Color(0xFFF0EEFF),
        card: Color(0xFF100E1E),
        cardForeground: Color(0xFFF0EEFF),
        primary: Color(0xFFC084FC),
        primaryForeground: Color(0xFF07050F),
        secondary: Color(0xFF1A1730),
        secondaryForeground: Color(0xFFE9D5FF),
        muted: Color(0xFF15122A),
        mutedForeground: Color(0xFF8B7DBA),
        accent: Color(0xFF2E1F5E),
        accentForeground: Color(0xFFE9D5FF),
        destructive: Color(0xFFEF4444),
        destructiveForeground: Color(0xFFFFFFFF),
        border: Color(0xFF1F1A38),
        input: Color(0xFF1F1A38),
        underweight: Color(0xFF3B82F6),
        normal: Color(0xFF10B981),
        overweight: Color(0xFFF59E0B),
        obese: Color(0xFFEF4444),
        cardBorder: Color(0x1FC084FC),
        male: Color(0xFF818CF8),
        female: Color(0xFFF472B6),
      );
}

extension ColorAlpha on Color {
  /// Mimics React's `color + "##"` hex-alpha appending.
  /// Pass an alpha value from 0 to 255.
  Color withA(int alpha) => withAlpha(alpha.clamp(0, 255));
}
