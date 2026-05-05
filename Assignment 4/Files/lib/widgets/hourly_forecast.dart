import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/weather_codes.dart';
import 'glass_card.dart';

class HourlyForecast extends StatelessWidget {
  final List<HourlyEntry> hourly;
  const HourlyForecast({super.key, required this.hourly});

  String _formatHour(String iso, int idx) {
    if (idx == 0) return 'Now';
    final d = DateTime.parse(iso);
    final h = d.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'HOURLY FORECAST',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.12), height: 0.5, thickness: 0.5),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              itemCount: hourly.length,
              itemBuilder: (ctx, i) {
                final h = hourly[i];
                final icon = WeatherCodes.iconForCondition(h.weatherCode, h.isDay);
                final iconColor = h.isDay ? const Color(0xFFFFD58A) : const Color(0xFFBFD0FF);
                final filled = (h.precipitationProbability / 100 * 4).round().clamp(0, 4);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatHour(h.time, i),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(icon, size: 26, color: iconColor),
                        if (h.precipitationProbability > 5)
                          Text(
                            '${h.precipitationProbability.round()}%',
                            style: const TextStyle(
                              color: Color(0xFF9DD2FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (j) => Container(
                            width: 5, height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: j < filled
                                  ? const Color(0xFF9DD2FF)
                                  : const Color(0xFF9DD2FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                        Text(
                          '${h.temperature.round()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
