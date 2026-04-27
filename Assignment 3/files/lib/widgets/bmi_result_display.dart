import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/theme_provider.dart';
import '../utils/bmi_utils.dart';

const _kStroke = 22.0;
const _kGapDeg = 60.0;
const _kStartDeg = 90.0 + _kGapDeg / 2;
const _kArcDeg = 360.0 - _kGapDeg;

class _Seg {
  final double end;
  final Color color;
  final String label;
  const _Seg(this.end, this.color, this.label);
}

List<_Seg> _segmentsFor(AppPalette colors) => [
      _Seg(18.5, colors.underweight, 'Underweight'),
      _Seg(25, colors.normal, 'Normal'),
      _Seg(30, colors.overweight, 'Overweight'),
      _Seg(40, colors.obese, 'Obese'),
    ];

double _bmiToSweep(double bmi) {
  final clamped = math.min(bmi, 40);
  final t = ((clamped - 10) / 30).clamp(0.0, 1.0);
  return t * _kArcDeg;
}

class BMIResultDisplay extends StatefulWidget {
  final double? bmi;
  const BMIResultDisplay({super.key, required this.bmi});

  @override
  State<BMIResultDisplay> createState() => _BMIResultDisplayState();
}

class _BMIResultDisplayState extends State<BMIResultDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _sweepCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _opacityCtrl;
  late Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
        value: 0.8,
        lowerBound: 0.8,
        upperBound: 1.0);
    _opacityCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _sweepAnim = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(
        parent: _sweepCtrl, curve: Curves.easeOutBack));
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant BMIResultDisplay old) {
    super.didUpdateWidget(old);
    if (old.bmi != widget.bmi) _maybeAnimate();
  }

  void _maybeAnimate() {
    if (widget.bmi == null) return;
    final target = _bmiToSweep(widget.bmi!);
    _sweepAnim = Tween<double>(begin: 0, end: target).animate(
        CurvedAnimation(parent: _sweepCtrl, curve: Curves.easeOutCubic));
    _sweepCtrl.forward(from: 0);
    _scaleCtrl.animateTo(1.0, curve: Curves.easeOutBack);
    _opacityCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _scaleCtrl.dispose();
    _opacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final bmi = widget.bmi;
    final size = math.min(MediaQuery.of(context).size.width - 80, 240.0);
    final segments = _segmentsFor(colors);

    final bmiColor =
        bmi != null ? getBMIColorForPalette(colors, bmi) : colors.primary;
    final category = bmi != null ? getBMICategory(bmi) : '';

    return FadeTransition(
      opacity: _opacityCtrl,
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _sweepAnim,
                    builder: (_, __) => CustomPaint(
                      size: Size(size, size),
                      painter: _ArcPainter(
                        sweep: _sweepAnim.value,
                        bmi: bmi,
                        bmiColor: bmiColor,
                        segments: segments,
                        muted: colors.muted,
                        cardColor: colors.card,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bmi != null ? bmi.toStringAsFixed(1) : '--',
                        style: GoogleFonts.inter(
                          fontSize: 52,
                          height: 56 / 52,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          color: bmiColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'BMI',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: colors.mutedForeground,
                        ),
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: bmiColor.withAlpha(0x18),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: bmiColor.withAlpha(0x35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    color: bmiColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: bmiColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double sweep;
  final double? bmi;
  final Color bmiColor;
  final List<_Seg> segments;
  final Color muted;
  final Color cardColor;

  _ArcPainter({
    required this.sweep,
    required this.bmi,
    required this.bmiColor,
    required this.segments,
    required this.muted,
    required this.cardColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - _kStroke * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    // Track
    final track = Paint()
      ..color = muted
      ..strokeWidth = _kStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      rect,
      _toRad(_kStartDeg - 90),
      _toRad(_kArcDeg),
      false,
      track,
    );

    // Segment hints
    for (int i = 0; i < segments.length; i++) {
      final segStart = i == 0 ? 10.0 : segments[i - 1].end;
      final segEnd = segments[i].end;
      final startSweep = ((segStart - 10) / 30) * _kArcDeg;
      final endSweep = ((segEnd - 10) / 30) * _kArcDeg;
      final p = Paint()
        ..color = segments[i].color.withValues(alpha: 0.22)
        ..strokeWidth = _kStroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        rect,
        _toRad(_kStartDeg - 90 + startSweep),
        _toRad(endSweep - startSweep),
        false,
        p,
      );
    }

    // Animated fill
    if (sweep > 0) {
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            bmiColor.withValues(alpha: 0.3),
            bmiColor,
          ],
        ).createShader(rect)
        ..strokeWidth = _kStroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        rect,
        _toRad(_kStartDeg - 90),
        _toRad(sweep),
        false,
        fill,
      );

      // Tip dot
      final tipDeg = _kStartDeg + sweep;
      final tipRad = _toRad(tipDeg - 90);
      final tip = Offset(
        center.dx + r * math.cos(tipRad),
        center.dy + r * math.sin(tipRad),
      );

      canvas.drawCircle(
          tip, _kStroke / 2 + 5, Paint()..color = cardColor);
      canvas.drawCircle(
          tip,
          _kStroke / 2 + 1,
          Paint()..color = bmiColor.withValues(alpha: 0.25));
      canvas.drawCircle(tip, _kStroke / 2 - 2, Paint()..color = bmiColor);
      canvas.drawCircle(tip, 4, Paint()..color = Colors.white);
    }
  }

  double _toRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.sweep != sweep ||
      old.bmi != bmi ||
      old.bmiColor != bmiColor ||
      !identical(old.segments, segments) ||
      old.muted != muted;
}
