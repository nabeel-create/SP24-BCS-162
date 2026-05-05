import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';

class UvCard extends StatelessWidget {
  final CurrentWeather current;
  const UvCard({super.key, required this.current});

  Map<String, dynamic> _uvInfo(double uv) {
    if (uv <= 2) return {'label': 'Low', 'color': const Color(0xFF7DDB8E), 'advice': 'Minimal risk — no protection needed.'};
    if (uv <= 5) return {'label': 'Moderate', 'color': const Color(0xFFFFD662), 'advice': 'Wear sunscreen SPF 30+ on exposed skin.'};
    if (uv <= 7) return {'label': 'High', 'color': const Color(0xFFFF9F40), 'advice': 'SPF 30+, hat & sunglasses. Limit midday exposure.'};
    if (uv <= 10) return {'label': 'Very High', 'color': const Color(0xFFFF6B6B), 'advice': 'SPF 50+, full coverage. Seek shade 10 AM–4 PM.'};
    return {'label': 'Extreme', 'color': const Color(0xFFCC44FF), 'advice': 'Avoid going outside. SPF 50+, full body coverage.'};
  }

  @override
  Widget build(BuildContext context) {
    final info = _uvInfo(current.uvIndex);
    final pct = (current.uvIndex / 12).clamp(0.0, 1.0);
    final color = info['color'] as Color;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.wb_sunny, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('UV INDEX', style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: SizedBox(
              height: 140,
              child: CustomPaint(
                size: const Size(double.infinity, 140),
                painter: _UvGaugePainter(pct: pct, color: color),
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                Text(current.uvIndex.round().toString(),
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(info['label'] as String,
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Text(info['advice'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UvGaugePainter extends CustomPainter {
  final double pct;
  final Color color;
  _UvGaugePainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.85;
    final r = math.min(size.width * 0.45, size.height * 0.82);

    // Background arc (180°)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      math.pi, math.pi, false,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Colored segments
    const segColors = [
      Color(0xFF7DDB8E), Color(0xFFFFD662), Color(0xFFFF9F40),
      Color(0xFFFF6B6B), Color(0xFFCC44FF),
    ];
    for (var i = 0; i < 5; i++) {
      final start = math.pi + (i / 5) * math.pi;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        start, math.pi / 5 - 0.04, false,
        Paint()
          ..color = segColors[i].withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Progress arc
    final sweepAngle = math.pi * pct;
    final arcShader = SweepGradient(
      colors: [const Color(0xFF7DDB8E), const Color(0xFFFFD662), const Color(0xFFFF9F40), color],
      startAngle: 0, endAngle: math.pi,
      tileMode: TileMode.clamp,
    ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2));

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      math.pi, sweepAngle, false,
      Paint()
        ..shader = arcShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Needle
    final needleAng = math.pi + pct * math.pi;
    const needleLen = 0.65;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * needleLen * math.cos(needleAng), cy + r * needleLen * math.sin(needleAng)),
      Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_UvGaugePainter old) => old.pct != pct;
}
