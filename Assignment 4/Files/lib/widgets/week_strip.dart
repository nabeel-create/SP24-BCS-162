import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/weather_codes.dart';

class WeekStrip extends StatelessWidget {
  final List<DailyEntry> daily;
  const WeekStrip({super.key, required this.daily});

  String _dayLabel(String iso, int idx) {
    if (idx == 0) return 'Today';
    if (idx == 1) return 'Tmrw';
    final d = DateTime.parse(iso);
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final days = daily.take(7).toList();
    final allMin = days.map((d) => d.tempMin).reduce((a, b) => a < b ? a : b);
    final allMax = days.map((d) => d.tempMax).reduce((a, b) => a > b ? a : b);
    final range = (allMax - allMin).clamp(1.0, double.infinity);

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final d = days[i];
          final barStart = (d.tempMin - allMin) / range;
          final barWidth = ((d.tempMax - d.tempMin) / range).clamp(0.08, 1.0);
          final icon = WeatherCodes.iconForCondition(d.weatherCode, true);

          return Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dayLabel(d.date, i),
                  style: TextStyle(
                    color: i == 0 ? const Color(0xFF7AB8FF) : Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Icon(icon, size: 22, color: const Color(0xFFFFD58A)),
                if (d.precipitationProbability >= 20)
                  Text(
                    '💧${d.precipitationProbability.round()}%',
                    style: const TextStyle(color: Color(0xFF9DD2FF), fontSize: 9),
                  )
                else
                  const SizedBox(height: 12),
                Text(
                  '${d.tempMax.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Bar
                LayoutBuilder(builder: (ctx, constraints) {
                  final totalW = constraints.maxWidth * 0.8;
                  return Container(
                    width: totalW,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      child: CustomPaint(
                        painter: _BarPainter(start: barStart, width: barWidth),
                      ),
                    ),
                  );
                }),
                Text(
                  '${d.tempMin.round()}°',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double start;
  final double width;
  _BarPainter({required this.start, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7AB8FF)
      ..style = PaintingStyle.fill;
    final left = start * size.width;
    final w = (width * size.width).clamp(4.0, size.width - left);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, size.height), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => false;
}
