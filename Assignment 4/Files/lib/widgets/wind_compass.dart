import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';

class WindCompass extends StatelessWidget {
  final CurrentWeather current;
  final String windSymbol;

  const WindCompass({super.key, required this.current, required this.windSymbol});

  String _directionLabel(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('WIND', style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _CompassPainter(direction: current.windDirection),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WindStat(label: 'Speed', value: '${current.windSpeed.round()} $windSymbol'),
                _WindStat(label: 'Direction', value: _directionLabel(current.windDirection)),
                _WindStat(label: 'Bearing', value: '${current.windDirection.round()}°'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindStat extends StatelessWidget {
  final String label;
  final String value;
  const _WindStat({required this.label, required this.value});

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

class _CompassPainter extends CustomPainter {
  final double direction;
  _CompassPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.82;

    // Background circle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 1);

    // Tick marks
    for (var i = 0; i < 36; i++) {
      final ang = (i / 36) * math.pi * 2;
      final isCard = i % 9 == 0;
      final len = isCard ? 12.0 : 5.0;
      final inner = r - len;
      canvas.drawLine(
        Offset(cx + inner * math.sin(ang), cy - inner * math.cos(ang)),
        Offset(cx + r * math.sin(ang), cy - r * math.cos(ang)),
        Paint()
          ..color = isCard ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.2)
          ..strokeWidth = isCard ? 1.5 : 0.5,
      );
    }

    // Cardinal labels
    const cardinals = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final ang = (i / 4) * math.pi * 2;
      final lx = cx + (r - 26) * math.sin(ang);
      final ly = cy - (r - 26) * math.cos(ang);
      final tp = TextPainter(
        text: TextSpan(text: cardinals[i], style: TextStyle(
          color: i == 0 ? const Color(0xFF7AB8FF) : Colors.white.withOpacity(0.7),
          fontSize: 13, fontWeight: FontWeight.w700,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // Wind direction needle
    final needleAng = (direction - 180) * math.pi / 180;
    final needleLen = r * 0.58;
    final needleTipX = cx + needleLen * math.sin(needleAng);
    final needleTipY = cy - needleLen * math.cos(needleAng);

    // Arrow shaft
    canvas.drawLine(
      Offset(cx, cy),
      Offset(needleTipX, needleTipY),
      Paint()
        ..color = const Color(0xFF7AB8FF)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head
    const headLen = 12.0;
    const headAngle = 0.45;
    final a1x = needleTipX - headLen * math.sin(needleAng - headAngle);
    final a1y = needleTipY + headLen * math.cos(needleAng - headAngle);
    final a2x = needleTipX - headLen * math.sin(needleAng + headAngle);
    final a2y = needleTipY + headLen * math.cos(needleAng + headAngle);

    final arrowPath = Path()
      ..moveTo(needleTipX, needleTipY)
      ..lineTo(a1x, a1y)
      ..lineTo(a2x, a2y)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF7AB8FF));

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = Colors.white.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.direction != direction;
}
