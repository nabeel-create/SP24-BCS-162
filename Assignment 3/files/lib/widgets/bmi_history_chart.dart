import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/bmi_record.dart';
import '../providers/theme_provider.dart';
import '../utils/bmi_utils.dart';
import 'dashed_panel.dart';

class BMIHistoryChart extends StatelessWidget {
  final List<BMIRecord> history;
  const BMIHistoryChart({super.key, required this.history});

  static const _chartHeight = 112.0;
  static const _valueHeight = 16.0;
  static const _valueGap = 6.0;
  static const _labelGap = 8.0;
  static const _labelHeight = 12.0;
  static const _barWidth = 40.0;
  static const _barGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final recent = history.take(10).toList().reversed.toList();

    if (recent.isEmpty) {
      return DashedPanel(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(12),
        color: colors.border,
        child: Text(
          'No history yet. Calculate your BMI to start tracking.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, color: colors.mutedForeground),
        ),
      );
    }

    final bmis = recent.map((r) => r.bmi).toList();
    final maxBMI = math.max<double>(bmis.reduce(math.max), 35);
    final minBMI = math.min<double>(bmis.reduce(math.min), 15);
    final range = maxBMI - minBMI;
    final safeRange = range <= 0 ? 1.0 : range;

    final screenW = MediaQuery.of(context).size.width;
    final minWidth = math.max(0.0, screenW - 72);
    const plotTop = _valueHeight + _valueGap;
    const plotBottom = _labelGap + _labelHeight;
    final contentWidth = recent.length * _barWidth +
        math.max(0, recent.length - 1) * _barGap;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth =
                constraints.hasBoundedWidth ? constraints.maxWidth : minWidth;
            final chartWidth = math.max(availableWidth, contentWidth);
            final gap = recent.length > 1
                ? math.max(
                    _barGap,
                    (chartWidth - (recent.length * _barWidth)) /
                        (recent.length - 1),
                  )
                : 0.0;

            return SizedBox(
              width: chartWidth,
              height: plotTop + _chartHeight + plotBottom,
              child: Stack(
                children: [
                  ...[15.0, 18.5, 25.0, 30.0].map((line) {
                    final y = _chartHeight -
                        ((line - minBMI) / safeRange) * _chartHeight;
                    if (y < 0 || y > _chartHeight) {
                      return const SizedBox.shrink();
                    }

                    return Positioned(
                      top: plotTop + y,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 1,
                        child: CustomPaint(
                          painter: _DashedLinePainter(color: colors.border),
                        ),
                      ),
                    );
                  }),
                  Row(
                    mainAxisAlignment: recent.length == 1
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < recent.length; i++) ...[
                        _bar(recent[i], minBMI, safeRange, colors),
                        if (i < recent.length - 1) SizedBox(width: gap),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bar(BMIRecord r, double minBMI, double range, dynamic colors) {
    final normalized = ((r.bmi - minBMI) / range).clamp(0.0, 1.0);
    final barH = math.max(8.0, normalized * _chartHeight);
    final color = getBMIColorForPalette(colors, r.bmi);
    final date = DateTime.parse(r.date).toLocal();
    final label = '${date.month}/${date.day}';

    return SizedBox(
      width: _barWidth,
      height: _valueHeight + _valueGap + _chartHeight + _labelGap + _labelHeight,
      child: Column(
        children: [
          SizedBox(
            height: _valueHeight,
            child: Center(
              child: Text(
                r.bmi.toStringAsFixed(1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: _valueGap),
          SizedBox(
            height: _chartHeight,
            width: double.infinity,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: barH,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: _labelGap),
          SizedBox(
            height: _labelHeight,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashGap = 4.0;
    double x = 0;
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), p);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
