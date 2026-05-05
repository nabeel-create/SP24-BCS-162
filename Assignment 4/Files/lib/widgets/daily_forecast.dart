import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/weather_codes.dart';
import 'glass_card.dart';

class DailyForecast extends StatelessWidget {
  final List<DailyEntry> daily;
  const DailyForecast({super.key, required this.daily});

  String _dayLabel(String iso, int idx) {
    if (idx == 0) return 'Today';
    final d = DateTime.parse(iso);
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[d.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final days = daily.take(7).toList();
    final allMin = days.map((d) => d.tempMin).reduce((a, b) => a < b ? a : b);
    final allMax = days.map((d) => d.tempMax).reduce((a, b) => a > b ? a : b);
    final range = (allMax - allMin).clamp(1.0, double.infinity);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('7-DAY FORECAST', style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.12), height: 0.5, thickness: 0.5),
          ...List.generate(days.length, (i) {
            final d = days[i];
            final icon = WeatherCodes.iconForCondition(d.weatherCode, true);
            final barStart = (d.tempMin - allMin) / range;
            final barWidth = ((d.tempMax - d.tempMin) / range).clamp(0.08, 1.0);
            final isLast = i == days.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(_dayLabel(d.date, i),
                            style: TextStyle(
                                color: i == 0 ? const Color(0xFF7AB8FF) : Colors.white,
                                fontSize: 14, fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500)),
                      ),
                      Icon(icon, size: 22, color: const Color(0xFFFFD58A)),
                      if (d.precipitationProbability >= 20)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('${d.precipitationProbability.round()}%',
                              style: const TextStyle(color: Color(0xFF9DD2FF), fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        )
                      else
                        const SizedBox(width: 36),
                      const Spacer(),
                      Text('${d.tempMin.round()}°',
                          style: TextStyle(color: Colors.white.withOpacity(0.45),
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      // Temp range bar
                      SizedBox(
                        width: 80,
                        height: 4,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: barStart + barWidth,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerRight,
                                widthFactor: barWidth / (barStart + barWidth),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFF9DD2FF), const Color(0xFFFFD262)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${d.tempMax.round()}°',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                      color: Colors.white.withOpacity(0.08),
                      height: 0.5, thickness: 0.5,
                      indent: 18, endIndent: 18),
              ],
            );
          }),
        ],
      ),
    );
  }
}
