import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final Color? backgroundColor;

  const DashedPanel({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        borderRadius: borderRadius,
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: Container(
        decoration: backgroundColor == null
            ? null
            : BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedRoundedRectPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(
      _dashPath(path, dashLength: dashLength, gapLength: gapLength),
      paint,
    );
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dashed = Path();

    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + gapLength;
      }
    }

    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
