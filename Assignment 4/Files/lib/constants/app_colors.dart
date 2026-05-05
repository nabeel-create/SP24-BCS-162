import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0B1026);
  static const Color primary = Color(0xFF7AB8FF);
  static const Color accent = Color(0xFFFFB36B);
  static const Color destructive = Color(0xFFFF6B6B);
  static const Color foreground = Colors.white;

  static Color card = Colors.white.withOpacity(0.08);
  static Color border = Colors.white.withOpacity(0.12);
  static Color muted = Colors.white.withOpacity(0.06);
  static Color mutedForeground = Colors.white.withOpacity(0.65);

  static const Color rainBlue = Color(0xFF9DD2FF);
  static const Color sunYellow = Color(0xFFFFE08A);
  static const Color sunOrange = Color(0xFFFFA552);
  static const Color nightBlue = Color(0xFFBFD0FF);
  static const Color uvGreen = Color(0xFF7DD87C);
  static const Color uvYellow = Color(0xFFFFD662);

  // Gradients by weather kind + isDay
  static List<Color> gradientForCondition(int code, bool isDay) {
    final kind = codeToKind(code);
    if (!isDay) {
      if (kind == 'clear') return [const Color(0xFF0B1026), const Color(0xFF1B2A5E), const Color(0xFF2D3F7E)];
      if (kind == 'rain' || kind == 'drizzle') return [const Color(0xFF0A0F24), const Color(0xFF1F2B47), const Color(0xFF3A4A6B)];
      if (kind == 'thunderstorm') return [const Color(0xFF06081A), const Color(0xFF1A1432), const Color(0xFF3A2858)];
      if (kind == 'snow') return [const Color(0xFF0F1A35), const Color(0xFF2C3D6A), const Color(0xFF5A7AB0)];
      return [const Color(0xFF0B1026), const Color(0xFF1B2A5E), const Color(0xFF2D3F7E)];
    }
    if (kind == 'clear') return [const Color(0xFF3F8DEF), const Color(0xFF7AB8FF), const Color(0xFFFFB36B)];
    if (kind == 'partly_cloudy') return [const Color(0xFF4A7FC4), const Color(0xFF7AAEDC), const Color(0xFFBFD8F0)];
    if (kind == 'cloudy') return [const Color(0xFF5C7493), const Color(0xFF8AA0BB), const Color(0xFFB5C5D8)];
    if (kind == 'fog') return [const Color(0xFF7B8C9E), const Color(0xFFA6B5C5), const Color(0xFFD4DCE5)];
    if (kind == 'drizzle' || kind == 'rain') return [const Color(0xFF34547A), const Color(0xFF5577A1), const Color(0xFF8AA5C5)];
    if (kind == 'snow') return [const Color(0xFF6B89B5), const Color(0xFFA8C0DC), const Color(0xFFE0EBF5)];
    if (kind == 'thunderstorm') return [const Color(0xFF1F2748), const Color(0xFF3A4470), const Color(0xFF6B6E94)];
    return [const Color(0xFF3F8DEF), const Color(0xFF7AB8FF), const Color(0xFFFFB36B)];
  }

  static String codeToKind(int code) {
    if (code == 0) return 'clear';
    if (code == 1 || code == 2) return 'partly_cloudy';
    if (code == 3) return 'cloudy';
    if (code == 45 || code == 48) return 'fog';
    if (code >= 51 && code <= 57) return 'drizzle';
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return 'rain';
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return 'snow';
    if (code >= 95 && code <= 99) return 'thunderstorm';
    return 'cloudy';
  }
}
