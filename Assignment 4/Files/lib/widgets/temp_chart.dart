import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';

class TempChart extends StatelessWidget {
  final List<HourlyEntry> hourly;
  const TempChart({super.key, required this.hourly});

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
    final temps = pts.map((p) => p.temperature).toList();
    final feels = pts.map((p) => p.apparentTemperature).toList();
    final allVals = [...temps, ...feels];
    final minT = allVals.reduce((a, b) => a < b ? a : b);
    final maxT = allVals.reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 13, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('NEXT 24 HOURS',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const Spacer(),
                Text('${temps.reduce((a, b) => a < b ? a : b).round()}° – '
                    '${temps.reduce((a, b) => a > b ? a : b).round()}°',
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _TempChartPainter(
                temps: temps,
                feelsLike: feels,
                minT: minT,
                maxT: maxT,
              ),
            ),
          ),
          // Time ticks
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [0, 6, 12, 18, pts.length - 1]
                  .where((idx) => idx < pts.length)
                  .map((idx) => Text(_fmtHour(pts[idx].time, idx),
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10)))
                  .toList(),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                Container(width: 18, height: 2.5, decoration: BoxDecoration(
                    color: const Color(0xFFFFD58A), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text('Actual', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                const SizedBox(width: 14),
                Container(width: 18, height: 0, decoration: BoxDecoration(
                  border: Border(top: BorderSide(
                      color: Colors.white.withOpacity(0.45), width: 1.5,
                      style: BorderStyle.solid)),
                )),
                const SizedBox(width: 5),
                Text('Feels like', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempChartPainter extends CustomPainter {
  final List<double> temps;
  final List<double> feelsLike;
  final double minT;
  final double maxT;

  _TempChartPainter({
    required this.temps,
    required this.feelsLike,
    required this.minT,
    required this.maxT,
  });

  List<Offset> _pts(List<double> vals, Size size) {
    final n = vals.length;
    final range = (maxT - minT).clamp(1.0, 999.0);
    final padX = 18.0, padTop = 24.0, padBottom = 26.0;
    return List.generate(n, (i) {
      final x = padX + (i / (n - 1)) * (size.width - padX * 2);
      final y = padTop + ((maxT - vals[i]) / range) * (size.height - padTop - padBottom);
      return Offset(x, y);
    });
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final midX = (prev.dx + cur.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(midX, (prev.dy + cur.dy) / 2, cur.dx, cur.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tPts = _pts(temps, size);
    final fPts = _pts(feelsLike, size);

    // Fill
    final fillPath = _smoothPath(tPts);
    fillPath.lineTo(tPts.last.dx, size.height - 26);
    fillPath.lineTo(tPts.first.dx, size.height - 26);
    fillPath.close();

    final fillShader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFFFFD58A).withOpacity(0.45), const Color(0xFFFFD58A).withOpacity(0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, Paint()..shader = fillShader..style = PaintingStyle.fill);

    // Temp line
    final linePath = _smoothPath(tPts);
    final lineShader = const LinearGradient(
      colors: [Color(0xFF9DD2FF), Color(0xFFFFE08A), Color(0xFFFFA552)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(linePath, Paint()
      ..shader = lineShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Feels-like dashed
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    _drawDashed(canvas, _smoothPath(fPts), dashPaint, 4, 4);

    // Min/max dots
    final maxIdx = temps.indexOf(temps.reduce((a, b) => a > b ? a : b));
    final minIdx = temps.indexOf(temps.reduce((a, b) => a < b ? a : b));

    canvas.drawCircle(tPts[maxIdx], 4, Paint()..color = const Color(0xFFFFA552));
    canvas.drawCircle(tPts[minIdx], 4, Paint()..color = const Color(0xFF9DD2FF));

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    _drawLabel(canvas, textPainter, '${temps.reduce((a, b) => a > b ? a : b).round()}°',
        tPts[maxIdx].translate(-12, -20), const Color(0xFFFFA552));
    _drawLabel(canvas, textPainter, '${temps.reduce((a, b) => a < b ? a : b).round()}°',
        tPts[minIdx].translate(-10, 6), const Color(0xFF9DD2FF));
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var d = 0.0;
      while (d < m.length) {
        final start = d;
        final end = (d + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(start, end), paint);
        d += dash + gap;
      }
    }
  }

  void _drawLabel(Canvas canvas, TextPainter tp, String text, Offset pos, Color color) {
    tp.text = TextSpan(text: text, style: TextStyle(
        color: color, fontSize: 12, fontWeight: FontWeight.w600));
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_TempChartPainter old) =>
      old.temps != temps || old.feelsLike != feelsLike;
}
