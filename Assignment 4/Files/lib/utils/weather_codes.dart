import 'package:flutter/material.dart';

class WeatherCodes {
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

  static String describeWeather(int code) {
    final kind = codeToKind(code);
    const map = {
      'clear': 'Clear sky',
      'partly_cloudy': 'Partly cloudy',
      'cloudy': 'Cloudy',
      'fog': 'Foggy',
      'drizzle': 'Drizzle',
      'rain': 'Rainy',
      'snow': 'Snowy',
      'thunderstorm': 'Thunderstorms',
    };
    return map[kind] ?? 'Cloudy';
  }

  static IconData iconForCondition(int code, bool isDay) {
    final kind = codeToKind(code);
    if (kind == 'clear') return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    if (kind == 'partly_cloudy') return isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
    if (kind == 'cloudy') return Icons.cloud_rounded;
    if (kind == 'fog') return Icons.cloud_rounded;
    if (kind == 'drizzle' || kind == 'rain') return Icons.umbrella_rounded;
    if (kind == 'snow') return Icons.ac_unit_rounded;
    if (kind == 'thunderstorm') return Icons.bolt_rounded;
    return Icons.wb_cloudy_rounded;
  }

  static String emojiForCondition(int code, bool isDay) {
    final kind = codeToKind(code);
    if (kind == 'clear') return isDay ? '☀️' : '🌙';
    if (kind == 'partly_cloudy') return isDay ? '⛅' : '🌙';
    if (kind == 'cloudy') return '☁️';
    if (kind == 'fog') return '🌫️';
    if (kind == 'drizzle') return '🌦️';
    if (kind == 'rain') return '🌧️';
    if (kind == 'snow') return '❄️';
    if (kind == 'thunderstorm') return '⛈️';
    return '☁️';
  }

  static Color iconColorForCondition(int code, bool isDay) {
    final kind = codeToKind(code);
    if (!isDay) return const Color(0xFFBFD0FF);
    if (kind == 'clear') return const Color(0xFFFFE08A);
    if (kind == 'snow') return const Color(0xFFE0EBF5);
    if (kind == 'thunderstorm') return const Color(0xFF9DD2FF);
    return const Color(0xFFFFD58A);
  }

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

  static Map<String, dynamic> aqiCategory(double aqi) {
    if (aqi <= 50) return {'label': 'Good', 'color': const Color(0xFF4CD964), 'advice': 'Air quality is excellent — perfect for outdoor activities.'};
    if (aqi <= 100) return {'label': 'Moderate', 'color': const Color(0xFFFFCC00), 'advice': 'Air quality is acceptable for most people.'};
    if (aqi <= 150) return {'label': 'Unhealthy for Sensitive', 'color': const Color(0xFFFF9500), 'advice': 'Sensitive groups should limit outdoor exertion.'};
    if (aqi <= 200) return {'label': 'Unhealthy', 'color': const Color(0xFFFF3B30), 'advice': 'Reduce prolonged outdoor activity.'};
    if (aqi <= 300) return {'label': 'Very Unhealthy', 'color': const Color(0xFFAF52DE), 'advice': 'Avoid outdoor exertion. Wear a mask outside.'};
    return {'label': 'Hazardous', 'color': const Color(0xFF8B0000), 'advice': 'Stay indoors. Use air purifiers if available.'};
  }

  static String formatLocalTime(String iso) {
    final m = RegExp(r'T(\d{2}):(\d{2})').firstMatch(iso);
    if (m == null) return iso;
    final h24 = int.parse(m.group(1)!);
    final min = m.group(2)!;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    var h = h24 % 12;
    if (h == 0) h = 12;
    return '$h:$min $ampm';
  }

  static bool isSevereWeather(int code) {
    return code >= 95 && code <= 99;
  }
}
