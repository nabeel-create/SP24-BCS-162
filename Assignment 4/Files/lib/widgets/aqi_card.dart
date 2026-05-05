import 'package:flutter/material.dart';
import 'glass_card.dart';
import '../utils/weather_codes.dart';

class AqiCard extends StatelessWidget {
  final double? aqi;
  const AqiCard({super.key, this.aqi});

  @override
  Widget build(BuildContext context) {
    if (aqi == null) return const SizedBox();
    final info = WeatherCodes.aqiCategory(aqi!);
    final color = info['color'] as Color;
    final pct = (aqi! / 300).clamp(0.0, 1.0);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('AIR QUALITY', style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(info['label'] as String,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${aqi!.round()}', style: const TextStyle(
                    color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300, height: 1)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('AQI', style: TextStyle(color: Colors.white.withOpacity(0.55),
                      fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(colors: [
                      const Color(0xFF4CD964), const Color(0xFFFFCC00),
                      const Color(0xFFFF9500), const Color(0xFFFF3B30), color,
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['0', '50', '100', '150', '200', '300'].map((v) =>
                  Text(v, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9))).toList(),
            ),
            const SizedBox(height: 12),
            Text(info['advice'] as String,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
