import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';

class RainChart extends StatelessWidget {
  final List<HourlyEntry> hourly;
  const RainChart({super.key, required this.hourly});

  String _fmtHour(String iso, int i) {
    if (i == 0) return 'Now';
    final d = DateTime.parse(iso);
    final ampm = d.hour >= 12 ? 'P' : 'A';
    var h = d.hour % 12;
    if (h == 0) h = 12;
    return '$h$ampm';
  }

  @override
  Widget build(BuildContext context) {
    final pts = hourly.take(24).toList();
    if (pts.length < 2) return const SizedBox();
    final hasRain = pts.any((p) => p.precipitationProbability > 0);
    final peak = pts.map((p) => p.precipitationProbability).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              children: [
                Icon(Icons.water, size: 13, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('RAIN CHANCE · 24H',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const Spacer(),
                if (peak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9DD2FF).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFF9DD2FF).withOpacity(0.35)),
                    ),
                    child: const Text('',
                        style: TextStyle(color: Color(0xFF9DD2FF), fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  Text('No rain expected',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          if (hasRain) ...[
            SizedBox(
              height: 110,
              child: CustomPaint(
                size: const Size(double.infinity, 110),
                painter: _RainChartPainter(points: pts),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0, 6, 12, 18, pts.length - 1]
                    .where((idx) => idx < pts.length)
                    .map((idx) => Text(_fmtHour(pts[idx].time, idx),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)))
                    .toList(),
              ),
            ),
          ] else
            Container(
              height: 90,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wb_sunny, size: 28, color: Color(0xFFFFD262)),
                  const SizedBox(width: 10),
                  Text('Clear skies ahead',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RainChartPainter extends CustomPainter {
  final List<HourlyEntry> points;
  _RainChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    const padX = 16.0, padTop = 14.0, padBottom = 22.0;
    final innerW = size.width - padX * 2;
    final innerH = size.height - padTop - padBottom;

    // 50% guide
    canvas.drawLine(
      Offset(padX, padTop + innerH / 2),
      Offset(padX + innerW, padTop + innerH / 2),
      Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 0.5,
    );

    // Bar rects
    final barW = (innerW / n * 0.65).clamp(4.0, 20.0);
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final x = padX + (i / (n - 1)) * innerW - barW / 2;
      final pct = p.precipitationProbability / 100;
      final bH = (pct * innerH).clamp(2.0, innerH);
      final y = padTop + innerH - bH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, bH), Radius.circular(barW / 2)),
        Paint()
          ..color = p.precipitationProbability > 70
              ? const Color(0xFF64B4FF).withOpacity(0.55)
              : const Color(0xFF9DD2FF).withOpacity(0.25),
      );
    }

    // Build area path
    final xs = List.generate(n, (i) => padX + (i / (n - 1)) * innerW);
    final ys = List.generate(n, (i) {
      return padTop + innerH - (points[i].precipitationProbability / 100) * innerH;
    });

    final areaPath = Path()
      ..moveTo(xs[0], padTop + innerH)
      ..lineTo(xs[0], ys[0]);
    for (var i = 1; i < n; i++) {
      final mx = (xs[i - 1] + xs[i]) / 2;
      areaPath.cubicTo(mx, ys[i - 1], mx, ys[i], xs[i], ys[i]);
    }
    areaPath.lineTo(xs.last, padTop + innerH);
    areaPath.close();

    final fillShader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF9DD2FF).withOpacity(0.55),
        const Color(0xFF9DD2FF).withOpacity(0.04),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, Paint()..shader = fillShader..style = PaintingStyle.fill);

    // Line
    final linePath = Path()..moveTo(xs[0], ys[0]);
    for (var i = 1; i < n; i++) {
      final mx = (xs[i - 1] + xs[i]) / 2;
      linePath.cubicTo(mx, ys[i - 1], mx, ys[i], xs[i], ys[i]);
    }
    final lineShader = const LinearGradient(
      colors: [Color(0xFF5BB8FF), Color(0xFF9DD2FF)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(linePath, Paint()
      ..shader = lineShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RainChartPainter old) => false;
}
