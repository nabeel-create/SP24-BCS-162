import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class BMISpinner extends StatefulWidget {
  final VoidCallback onDone;
  final int durationMs;

  const BMISpinner({
    super.key,
    required this.onDone,
    this.durationMs = 3000,
  });

  @override
  State<BMISpinner> createState() => _BMISpinnerState();
}

class _BMISpinnerState extends State<BMISpinner>
    with TickerProviderStateMixin {
  static const _dots = [
    'Measuring height & weight',
    'Calculating your BMI',
    'Analyzing health data',
    'Preparing your results',
  ];
  static const _pulseExpandMs = 1000;
  static const _pulseReturnMs = 600;

  late final AnimationController _rotate;
  late final AnimationController _pulse1;
  late final AnimationController _pulse2;
  late final AnimationController _pulse3;
  late final AnimationController _progress;
  late final AnimationController _fade;
  Timer? _dotTimer;
  Timer? _doneTimer;
  int _dotIdx = 0;

  @override
  void initState() {
    super.initState();

    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _pulse1 = _makePulse(0);
    _pulse2 = _makePulse(350);
    _pulse3 = _makePulse(700);

    _progress = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            widget.durationMs > 300 ? widget.durationMs - 300 : widget.durationMs,
      ),
    )..forward();

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    final dotInterval =
        Duration(milliseconds: (widget.durationMs / _dots.length).round());
    _dotTimer = Timer.periodic(dotInterval, (_) {
      if (!mounted) return;
      setState(() => _dotIdx++);
    });

    _doneTimer = Timer(Duration(milliseconds: widget.durationMs), () {
      if (mounted) widget.onDone();
    });
  }

  AnimationController _makePulse(int delayMs) {
    return AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: delayMs + _pulseExpandMs + _pulseReturnMs,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _doneTimer?.cancel();
    _rotate.dispose();
    _pulse1.dispose();
    _pulse2.dispose();
    _pulse3.dispose();
    _progress.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final dot = _dots[_dotIdx % _dots.length];
    final progress =
        CurvedAnimation(parent: _progress, curve: Curves.easeOutCubic);

    return FadeTransition(
      opacity: _fade,
      child: AbsorbPointer(
        child: SizedBox.expand(
          child: ColoredBox(
            color: colors.background,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildPulse(_pulse1, colors.primary, 0x40, 0),
                            _buildPulse(_pulse2, colors.primary, 0x28, 350),
                            _buildPulse(_pulse3, colors.primary, 0x18, 700),
                            RotationTransition(
                              turns: _rotate,
                              child: CustomPaint(
                                size: const Size(120, 120),
                                painter: _SpinnerArcPainter(
                                  primary: colors.primary,
                                  muted: colors.muted,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BMI',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'analyzing',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        dot,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          width: double.infinity,
                          height: 5,
                          child: Stack(
                            children: [
                              Container(color: colors.muted),
                              AnimatedBuilder(
                                animation: progress,
                                builder: (_, __) => FractionallySizedBox(
                                  widthFactor: progress.value,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulse(
    AnimationController controller,
    Color color,
    int hexAlpha,
    int delayMs,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final totalMs = delayMs + _pulseExpandMs + _pulseReturnMs;
        final elapsedMs = controller.value * totalMs;

        double scale;
        if (elapsedMs <= delayMs) {
          scale = 1;
        } else if (elapsedMs <= delayMs + _pulseExpandMs) {
          final expandProgress = (elapsedMs - delayMs) / _pulseExpandMs;
          scale = 1 + 0.6 * expandProgress;
        } else {
          final returnProgress =
              (elapsedMs - delayMs - _pulseExpandMs) / _pulseReturnMs;
          scale = 1.6 - 0.6 * returnProgress.clamp(0.0, 1.0).toDouble();
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withAlpha(hexAlpha),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpinnerArcPainter extends CustomPainter {
  final Color primary;
  final Color muted;

  _SpinnerArcPainter({
    required this.primary,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 50.0;
    const stroke = 8.0;

    final track = Paint()
      ..color = muted
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary.withValues(alpha: 0.2), primary],
      ).createShader(rect)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, arc);
  }

  @override
  bool shouldRepaint(covariant _SpinnerArcPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.muted != muted;
  }
}
