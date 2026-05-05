import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';
import '../utils/weather_codes.dart';

class SunArc extends StatelessWidget {
  final CurrentWeather current;
  const SunArc({super.key, required this.current});

  double _parseHM(String iso) {
    try {
      final d = DateTime.parse(iso);
      return d.hour + d.minute / 60.0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sunrise = _parseHM(current.sunrise);
    final sunset = _parseHM(current.sunset);
    final now = DateTime.now().hour + DateTime.now().minute / 60.0;
    final progress = ((now - sunrise) / (sunset - sunrise)).clamp(0.0, 1.0);
    final dawnAngle = sunrise / 24 * 360;
    final duskAngle = sunset / 24 * 360;
    final dayLen = sunset - sunrise;
    final h = dayLen.floor();
    final m = ((dayLen - h) * 60).round();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('SUN TIMES', style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _SunArcPainter(progress: progress),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoCol(label: 'Sunrise', value: WeatherCodes.formatLocalTime(current.sunrise)),
                _InfoCol(label: 'Daylight', value: '${h}h ${m}m'),
                _InfoCol(label: 'Sunset', value: WeatherCodes.formatLocalTime(current.sunset)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SunArcPainter extends CustomPainter {
  final double progress;
  _SunArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final rx = size.width * 0.4;
    final ry = size.height * 0.78;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        math.pi, math.pi, false, bgPaint);

    // Gradient arc for progress
    final arcPath = Path();
    final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    arcPath.addArc(rect, math.pi, sweepAngle);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gradient = LinearGradient(
      colors: [const Color(0xFFFF9500), const Color(0xFFFFD262), const Color(0xFFFFA552)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    arcPaint.shader = gradient;
    canvas.drawPath(arcPath, arcPaint);

    // Horizon line
    canvas.drawLine(
      Offset(cx - rx, cy),
      Offset(cx + rx, cy),
      Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 0.5,
    );

    // Sun position
    final angle = math.pi + math.pi * progress;
    final sunX = cx + rx * math.cos(angle);
    final sunY = cy + ry * math.sin(angle);

    // Glow
    canvas.drawCircle(Offset(sunX, sunY), 14,
        Paint()..color = const Color(0xFFFFD262).withOpacity(0.3));
    canvas.drawCircle(Offset(sunX, sunY), 9,
        Paint()..color = const Color(0xFFFFD262));

    // Sunrise/sunset markers
    final srX = cx - rx;
    final ssX = cx + rx;
    canvas.drawCircle(Offset(srX, cy), 4,
        Paint()..color = const Color(0xFFFFAA00));
    canvas.drawCircle(Offset(ssX, cy), 4,
        Paint()..color = const Color(0xFFFF6B00));

    // Label helpers
    void drawLabel(String text, Offset pos, Color color) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, 0));
    }
    drawLabel('↑', Offset(srX, cy + 10), const Color(0xFFFFAA00));
    drawLabel('↓', Offset(ssX, cy + 10), const Color(0xFFFF6B00));
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.progress != progress;
}
