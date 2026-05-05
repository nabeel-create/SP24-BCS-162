import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/weather_codes.dart';
import 'glass_card.dart';

class _Suggestion {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Suggestion({required this.icon, required this.title, required this.body, required this.color});
}

List<_Suggestion> _buildSuggestions(CurrentWeather current, List<DailyEntry> daily, double? aqi) {
  final out = <_Suggestion>[];
  final kind = WeatherCodes.codeToKind(current.weatherCode);
  final today = daily.isNotEmpty ? daily[0] : null;
  final rainChance = today?.precipitationProbability ?? 0;

  if (kind == 'rain' || kind == 'drizzle' || rainChance > 50) {
    out.add(_Suggestion(icon: Icons.umbrella, title: 'Carry an umbrella',
        body: '${rainChance.round()}% rain chance today — don\'t get caught out.',
        color: const Color(0xFF5DA8FF)));
  }
  if (kind == 'thunderstorm') {
    out.add(_Suggestion(icon: Icons.warning_amber, title: 'Storms incoming',
        body: 'Avoid open areas during thunderstorms.', color: const Color(0xFFFFB36B)));
  }
  if (kind == 'snow') {
    out.add(_Suggestion(icon: Icons.ac_unit, title: 'Bundle up warm',
        body: 'Snow expected — wear insulated layers.', color: const Color(0xFFBFD0FF)));
  }
  if (current.temperature >= 30) {
    out.add(_Suggestion(icon: Icons.water_drop, title: 'Stay hydrated',
        body: '${current.temperature.round()}° — drink plenty of water today.',
        color: const Color(0xFFFF8C5A)));
  }
  if (current.temperature <= 5) {
    out.add(_Suggestion(icon: Icons.dry_cleaning, title: 'Dress warmly',
        body: 'Wear a heavy coat, gloves, and scarf.', color: const Color(0xFF9DC8FF)));
  }
  if (current.uvIndex >= 6) {
    out.add(_Suggestion(icon: Icons.wb_sunny, title: 'Use sunscreen',
        body: 'UV index ${current.uvIndex.round()} — protect your skin outdoors.',
        color: const Color(0xFFFFD700)));
  }
  if (current.windSpeed >= 25) {
    out.add(_Suggestion(icon: Icons.navigation, title: 'Windy outside',
        body: '${current.windSpeed.round()} km/h winds — secure loose items.',
        color: const Color(0xFFA8E0FF)));
  }
  if (aqi != null && aqi > 100) {
    out.add(_Suggestion(icon: Icons.eco, title: 'Air quality alert',
        body: 'Limit outdoor exertion — sensitive groups especially.',
        color: const Color(0xFFFF6B6B)));
  }
  if (kind == 'clear' && current.isDay && current.temperature >= 18 && current.temperature <= 26) {
    out.add(_Suggestion(icon: Icons.directions_walk, title: 'Perfect for a walk',
        body: 'Clear skies and mild temps — great time to get outside.',
        color: const Color(0xFF7DDB8E)));
  }
  if (!out.any((s) => s.icon == Icons.umbrella) && rainChance > 0) {
    out.add(_Suggestion(icon: Icons.grain, title: 'Rain chance today',
        body: '${rainChance.round()}% probability of precipitation — keep an eye on the sky.',
        color: const Color(0xFF5DA8FF)));
  }
  if (out.isEmpty) {
    out.add(_Suggestion(icon: Icons.auto_awesome, title: 'Pleasant conditions',
        body: 'Nothing unusual on the radar — have a great day.',
        color: const Color(0xFF7AB8FF)));
  }
  if (out.length == 1) {
    out.add(_Suggestion(icon: Icons.thermostat, title: 'Today\'s forecast',
        body: today != null
            ? 'High ${today.tempMax.round()}° · Low ${today.tempMin.round()}° · ${rainChance.round()}% rain'
            : 'Check back for updated conditions.',
        color: const Color(0xFF7AB8FF)));
  }
  return out;
}

class SmartSuggestions extends StatelessWidget {
  final CurrentWeather current;
  final List<DailyEntry> daily;
  final double? aqi;

  const SmartSuggestions({super.key, required this.current, required this.daily, this.aqi});

  @override
  Widget build(BuildContext context) {
    final items = _buildSuggestions(current, daily, aqi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 14, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text('SMART SUGGESTIONS', style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final s = items[i];
              return SizedBox(
                width: MediaQuery.of(ctx).size.width * 0.44,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, size: 22, color: s.color),
                      ),
                      const SizedBox(height: 10),
                      Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(s.body, style: TextStyle(
                            color: Colors.white.withOpacity(0.65), fontSize: 11, height: 1.4),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
