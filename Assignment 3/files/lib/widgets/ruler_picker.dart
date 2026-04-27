import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Faithful Flutter port of the source RulerPicker:
/// - Horizontal scrollable ticks
/// - Major / minor / selected tick heights & widths
/// - Center cursor with triangle pointer
/// - Soft fade edges
/// - Snap to tick on scroll end + haptic feedback
class RulerPicker extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final Color accentColor;
  final int majorEvery;
  final int labelEvery;
  final double itemWidth;
  final ValueChanged<double> onChange;

  const RulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.accentColor,
    this.majorEvery = 5,
    this.labelEvery = 10,
    this.itemWidth = 18,
    required this.onChange,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late ScrollController _ctrl;
  double _committed = 0;
  double _displayValue = 0;
  bool _ready = false;
  bool _skipNext = false;
  double _trackWidth = 0;

  static const double _tickSelected = 34;
  static const double _tickMajor = 20;
  static const double _tickMinor = 10;

  int get _count =>
      ((widget.max - widget.min) / widget.step).round() + 1;

  double _valueToOffset(double v) =>
      ((v - widget.min) / widget.step).round() * widget.itemWidth;

  double _offsetToValue(double offset) {
    final idx = (offset / widget.itemWidth).round();
    final clamped = idx.clamp(0, _count - 1);
    return ((widget.min + clamped * widget.step) * 10).round() / 10;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    _committed = widget.value;
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant RulerPicker old) {
    super.didUpdateWidget(old);
    if ((widget.value - _displayValue).abs() >= widget.step / 2) {
      _displayValue = widget.value;
    }
    if (!_ready) {
      return;
    }
    if ((widget.value - _committed).abs() < widget.step / 2) {
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final target = _valueToOffset(widget.value);
    final current = _ctrl.hasClients ? _ctrl.offset : 0;
    if ((target - current).abs() < 0.5) {
      _committed = widget.value;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _skipNext = true;
    _committed = widget.value;
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctrl.hasClients) {
        _ctrl.animateTo(target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut);
      }
    });
  }

  void _onLayout(double width) {
    if (_trackWidth == width && _ready) return;
    _trackWidth = width;
    _ready = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ctrl.hasClients) return;
      _skipNext = true;
      _ctrl.jumpTo(_valueToOffset(widget.value));
      _displayValue = widget.value;
      setState(() {});
    });
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      if (_skipNext) {
        _skipNext = false;
        return false;
      }
      final v = _offsetToValue(n.metrics.pixels);
      if (v != _committed) {
        _committed = v;
        _displayValue = v;
        setState(() {});
        HapticFeedback.lightImpact();
        widget.onChange(v);
      }
    } else if (n is ScrollEndNotification) {
      _skipNext = false;
      final v = _offsetToValue(n.metrics.pixels);
      _committed = v;
      _displayValue = v;
      setState(() {});
      widget.onChange(v);
      // Snap precisely to tick
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_ctrl.hasClients) return;
        final target = _valueToOffset(v);
        if ((target - _ctrl.offset).abs() > 0.5) {
          _skipNext = true;
          _ctrl.animateTo(target,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut);
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return LayoutBuilder(
      builder: (context, c) {
        _onLayout(c.maxWidth);
        final halfPad =
            _trackWidth > 0 ? _trackWidth / 2 - widget.itemWidth / 2 : 0.0;

        return SizedBox(
          height: 84,
          child: Stack(
            children: [
              if (_ready)
                NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: ListView.builder(
                    controller: _ctrl,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                        decelerationRate: ScrollDecelerationRate.fast),
                    padding:
                        EdgeInsets.symmetric(horizontal: halfPad.toDouble()),
                    itemCount: _count,
                    itemExtent: widget.itemWidth,
                    itemBuilder: (context, i) {
                      final v = ((widget.min + i * widget.step) * 10).round() /
                          10;
                      final dist =
                          ((v - _displayValue).abs()) / widget.step;
                      final isMajor = i % widget.majorEvery == 0;
                      final showLabel = i % widget.labelEvery == 0;
                      final isSelected = dist < 0.6;

                      final tickH = isSelected
                          ? _tickSelected
                          : isMajor
                              ? _tickMajor
                              : _tickMinor;
                      final tickW =
                          isSelected ? 3.0 : (isMajor ? 1.5 : 1.0);
                      final opacity = isSelected
                          ? 1.0
                          : (1 - dist * 0.055).clamp(0.15, 1.0);

                      final bg = isSelected
                          ? widget.accentColor
                          : colors.mutedForeground;

                      return Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: tickH,
                              width: tickW,
                              decoration: BoxDecoration(
                                color: bg.withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (showLabel)
                              Text(
                                _fmt(v),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: isSelected ? 10 : 8,
                                  height: 1,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? widget.accentColor
                                      : colors.mutedForeground.withValues(alpha: 
                                          isSelected
                                              ? 1
                                              : (opacity > 0.35
                                                  ? opacity
                                                  : 0.35)),
                                ),
                              )
                            else
                              const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              // Soft fades
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 44,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colors.card.withValues(alpha: 0.85),
                          colors.card.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 44,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          colors.card.withValues(alpha: 0.85),
                          colors.card.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Center cursor
              IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _TrianglePainter(widget.accentColor),
                        ),
                        Expanded(
                          child: Container(
                            width: 2.5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    if (widget.step >= 1) return v.round().toString();
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}
