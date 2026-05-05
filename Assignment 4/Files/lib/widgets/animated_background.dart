import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/weather_codes.dart';

class AnimatedBackground extends StatefulWidget {
  final int weatherCode;
  final bool isDay;

  const AnimatedBackground({
    super.key,
    required this.weatherCode,
    required this.isDay,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _orb1Ctrl;
  late AnimationController _orb2Ctrl;
  late AnimationController _orb3Ctrl;
  late AnimationController _particleCtrl;
  late AnimationController _lightningCtrl;

  @override
  void initState() {
    super.initState();
    _orb1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat(reverse: true);
    _orb2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 11500))
      ..repeat(reverse: true);
    _orb3Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 13000))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _lightningCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat();
  }

  @override
  void dispose() {
    _orb1Ctrl.dispose();
    _orb2Ctrl.dispose();
    _orb3Ctrl.dispose();
    _particleCtrl.dispose();
    _lightningCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = WeatherCodes.gradientForCondition(widget.weatherCode, widget.isDay);
    final kind = WeatherCodes.codeToKind(widget.weatherCode);

    return Positioned.fill(
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),

          // Orb 1
          AnimatedBuilder(
            animation: _orb1Ctrl,
            builder: (ctx, _) {
              final t = _orb1Ctrl.value;
              return Positioned(
                left: MediaQuery.of(ctx).size.width * 0.05 + (t - 0.5) * 80 - 170,
                top: MediaQuery.of(ctx).size.height * 0.04 + (t - 0.5) * 60 - 170,
                child: Opacity(
                  opacity: (0.28 + t * 0.22).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.88 + t * 0.24,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDay
                            ? const Color(0xFFFF8C00).withOpacity(0.30)
                            : const Color(0xFF7890FF).withOpacity(0.22),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Orb 2
          AnimatedBuilder(
            animation: _orb2Ctrl,
            builder: (ctx, _) {
              final t = _orb2Ctrl.value;
              return Positioned(
                left: MediaQuery.of(ctx).size.width * 0.5 + (t - 0.5) * 80 - 130,
                top: MediaQuery.of(ctx).size.height * 0.32 + (t - 0.5) * 60 - 130,
                child: Opacity(
                  opacity: (0.28 + t * 0.22).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.88 + t * 0.24,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDay
                            ? Colors.white.withOpacity(0.18)
                            : const Color(0xFFB496FF).withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Orb 3
          AnimatedBuilder(
            animation: _orb3Ctrl,
            builder: (ctx, _) {
              final t = _orb3Ctrl.value;
              return Positioned(
                left: MediaQuery.of(ctx).size.width * 0.15 + (t - 0.5) * 80 - 100,
                top: MediaQuery.of(ctx).size.height * 0.62 + (t - 0.5) * 60 - 100,
                child: Opacity(
                  opacity: (0.28 + t * 0.22).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.88 + t * 0.24,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDay
                            ? const Color(0xFF78B4FF).withOpacity(0.25)
                            : const Color(0xFF5078C8).withOpacity(0.28),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Weather particles
          if (kind == 'rain' || kind == 'drizzle')
            _RainOverlay(ctrl: _particleCtrl, count: kind == 'drizzle' ? 28 : 50),
          if (kind == 'thunderstorm')
            _ThunderstormOverlay(ctrl: _particleCtrl, lightningCtrl: _lightningCtrl),
          if (kind == 'snow')
            _SnowOverlay(ctrl: _particleCtrl),
          if (kind == 'fog')
            _FogOverlay(ctrl: _particleCtrl),
          if (kind == 'cloudy' || kind == 'partly_cloudy')
            _CloudOverlay(ctrl: _particleCtrl),
        ],
      ),
    );
  }
}

double _rnd(double seed) {
  final x = math.sin(seed * 127.1 + 311.7) * 43758.5;
  return x - x.floor();
}

// ─── Rain ──────────────────────────────────────────────────────────────────
class _RainOverlay extends StatelessWidget {
  final AnimationController ctrl;
  final int count;
  const _RainOverlay({required this.ctrl, required this.count});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          final t = ctrl.value;
          return CustomPaint(
            painter: _RainPainter(t: t, count: count, size: size),
          );
        },
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double t;
  final int count;
  final Size size;

  _RainPainter({required this.t, required this.count, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()
      ..color = const Color(0xFFCCE1FF).withOpacity(0.85)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final x = _rnd(i * 3 + 1) * size.width;
      final phase = _rnd(i * 3 + 2);
      final len = 10 + _rnd(i + 99) * 8;
      final opacity = 0.35 + _rnd(i + 77) * 0.45;
      final slant = 8 + _rnd(i + 55) * 14;
      final totalH = size.height + 160;
      final yBase = (phase + t) % 1.0 * totalH - 80;
      final xOffset = (yBase / totalH) * slant;

      paint.color = const Color(0xFFCCE1FF).withOpacity(opacity);
      canvas.drawLine(
        Offset(x + xOffset, yBase),
        Offset(x + xOffset + slant * 0.3, yBase + len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}

// ─── Thunderstorm ──────────────────────────────────────────────────────────
class _ThunderstormOverlay extends StatelessWidget {
  final AnimationController ctrl;
  final AnimationController lightningCtrl;
  const _ThunderstormOverlay({required this.ctrl, required this.lightningCtrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: ctrl,
            builder: (ctx, _) {
              final size = MediaQuery.of(ctx).size;
              return CustomPaint(
                painter: _RainPainter(t: ctrl.value, count: 60, size: size),
              );
            },
          ),
          AnimatedBuilder(
            animation: lightningCtrl,
            builder: (ctx, _) {
              final t = lightningCtrl.value;
              final flash = (t < 0.06 || (t > 0.1 && t < 0.14)) ? 1.0 : 0.0;
              return Opacity(
                opacity: flash * 0.55,
                child: Container(color: const Color(0xFFD0E8FF)),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Snow ──────────────────────────────────────────────────────────────────
class _SnowOverlay extends StatelessWidget {
  final AnimationController ctrl;
  const _SnowOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          return CustomPaint(
            painter: _SnowPainter(t: ctrl.value, size: size),
          );
        },
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  final double t;
  final Size size;
  _SnowPainter({required this.t, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = Colors.white.withOpacity(0.92);
    for (var i = 0; i < 40; i++) {
      final x = _rnd(i * 7 + 1) * size.width;
      final phase = _rnd(i * 7 + 2);
      final flakeSize = 2 + _rnd(i + 300) * 5;
      final swayAmp = 20 + _rnd(i + 320) * 40;
      final opacity = 0.5 + _rnd(i + 360) * 0.45;
      final totalH = size.height + 160;
      final yBase = (phase + t * 0.3) % 1.0 * totalH - 80;
      final sway = math.sin(t * math.pi * 2 + i) * swayAmp;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x + sway, yBase), flakeSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => old.t != t;
}

// ─── Fog ──────────────────────────────────────────────────────────────────
class _FogOverlay extends StatelessWidget {
  final AnimationController ctrl;
  const _FogOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          return CustomPaint(
            painter: _FogPainter(t: ctrl.value, size: size),
          );
        },
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final double t;
  final Size size;
  _FogPainter({required this.t, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 10; i++) {
      final y = 60 + _rnd(i * 13 + 1) * (size.height - 100);
      final h = 60 + _rnd(i * 13 + 2) * 80;
      final w = size.width * 1.4;
      final duration = 0.3 + _rnd(i * 13 + 3) * 0.2;
      final goRight = _rnd(i * 13 + 4) > 0.5;
      final opacity = 0.04 + _rnd(i * 13 + 5) * 0.06;
      final phase = _rnd(i * 13 + 6);

      final progress = (phase + t * duration) % 1.0;
      final x = goRight
          ? -w + progress * (size.width + w)
          : size.width - progress * (size.width + w);

      paint.color = Colors.white.withOpacity(opacity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - h / 2, w, h),
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_FogPainter old) => old.t != t;
}

// ─── Clouds ──────────────────────────────────────────────────────────────
class _CloudOverlay extends StatelessWidget {
  final AnimationController ctrl;
  const _CloudOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          return CustomPaint(
            painter: _CloudPainter(t: ctrl.value, size: size),
          );
        },
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double t;
  final Size size;
  _CloudPainter({required this.t, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 8; i++) {
      final y = 20 + _rnd(i * 17 + 1) * (size.height * 0.45);
      final w = 180 + _rnd(i * 17 + 2) * 200;
      final h = 60 + _rnd(i * 17 + 3) * 60;
      final duration = 0.1 + _rnd(i * 17 + 4) * 0.05;
      final goRight = _rnd(i * 17 + 5) > 0.5;
      final opacity = 0.05 + _rnd(i * 17 + 6) * 0.09;
      final phase = _rnd(i * 17 + 7);

      final progress = (phase + t * duration) % 1.0;
      final x = goRight
          ? -w + progress * (size.width + w)
          : size.width - progress * (size.width + w);

      paint.color = Colors.white.withOpacity(opacity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - h / 2, w, h),
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.t != t;
}
