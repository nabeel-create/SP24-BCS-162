import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum BackgroundVariant { normal, win, lose }

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.variant = BackgroundVariant.normal,
  });

  final Widget child;
  final BackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    return MeshBackground(variant: variant, child: child);
  }
}

class MeshBackground extends StatefulWidget {
  const MeshBackground({
    super.key,
    required this.child,
    this.variant = BackgroundVariant.normal,
  });

  final Widget child;
  final BackgroundVariant variant;

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseGradient = _baseGradient(colors, isDark, widget.variant);
    final blobColors = _blobColors(colors, widget.variant);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          color: colors.background,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: baseGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const <double>[0, 0.35, 0.7, 1],
                  ),
                ),
              ),
              _BlobLayer(colors: blobColors, value: value),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x7306030F)
                      : const Color(0x40FFFFFF),
                ),
              ),
              Sparkles(
                count: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : widget.variant == BackgroundVariant.win
                        ? colors.success.withValues(alpha: 0.60)
                        : widget.variant == BackgroundVariant.lose
                            ? colors.destructive.withValues(alpha: 0.55)
                            : colors.primary.withValues(alpha: 0.45),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  List<Color> _baseGradient(
    AppColors colors,
    bool isDark,
    BackgroundVariant variant,
  ) {
    if (isDark) {
      switch (variant) {
        case BackgroundVariant.win:
          return const <Color>[
            Color(0xFF06030F),
            Color(0xFF0F0A25),
            Color(0xFF1A0A30),
            Color(0xFF06030F),
          ];
        case BackgroundVariant.lose:
          return const <Color>[
            Color(0xFF06030F),
            Color(0xFF1A0A25),
            Color(0xFF250515),
            Color(0xFF06030F),
          ];
        case BackgroundVariant.normal:
          return const <Color>[
            Color(0xFF06030F),
            Color(0xFF0F0825),
            Color(0xFF1A0A35),
            Color(0xFF06030F),
          ];
      }
    }

    switch (variant) {
      case BackgroundVariant.win:
        return const <Color>[
          Color(0xFFECFDF5),
          Color(0xFFF0F9FF),
          Color(0xFFFEF3C7),
          Color(0xFFFFF7ED),
        ];
      case BackgroundVariant.lose:
        return const <Color>[
          Color(0xFFFEE2E2),
          Color(0xFFFEF2F2),
          Color(0xFFFFF7ED),
          Color(0xFFF4F0FF),
        ];
      case BackgroundVariant.normal:
        return const <Color>[
          Color(0xFFF4F0FF),
          Color(0xFFFDF2F8),
          Color(0xFFFEF3C7),
          Color(0xFFF4F0FF),
        ];
    }
  }

  List<Color> _blobColors(AppColors colors, BackgroundVariant variant) {
    switch (variant) {
      case BackgroundVariant.win:
        return <Color>[colors.success, colors.blob3, colors.accent];
      case BackgroundVariant.lose:
        return <Color>[colors.destructive, colors.blob2, colors.accent];
      case BackgroundVariant.normal:
        return <Color>[colors.blob1, colors.blob2, colors.blob3];
    }
  }
}

class _BlobLayer extends StatelessWidget {
  const _BlobLayer({required this.colors, required this.value});

  final List<Color> colors;
  final double value;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildBlob(
          size: Size(size.width * 0.95, size.width * 0.95),
          left: -size.width * 0.3 + sin(value * pi * 2) * 40,
          top: -size.height * 0.05 + cos(value * pi * 2) * 30,
          color: colors[0].withValues(alpha: isDark ? 0.32 : 0.50),
        ),
        _buildBlob(
          size: Size(size.width * 0.85, size.width * 0.85),
          left: size.width * 0.4 + sin(value * pi * 2 + 1.1) * -50,
          top: size.height * 0.15 + cos(value * pi * 2 + 0.4) * 40,
          color: colors[1].withValues(alpha: isDark ? 0.28 : 0.45),
        ),
        _buildBlob(
          size: Size(size.width * 0.7, size.width * 0.7),
          left: -size.width * 0.1 + sin(value * pi * 2 + 2.4) * 60,
          top: size.height * 0.5 + cos(value * pi * 2 + 1.7) * -30,
          color: colors[2].withValues(alpha: isDark ? 0.22 : 0.40),
        ),
        _buildBlob(
          size: Size(size.width * 0.6, size.width * 0.6),
          left: size.width * 0.5 + sin(value * pi * 2 + 4.1) * -40,
          top: size.height * 0.7 + cos(value * pi * 2 + 0.9) * -50,
          color: colors[0].withValues(alpha: isDark ? 0.20 : 0.35),
        ),
      ],
    );
  }

  Widget _buildBlob({
    required Size size,
    required double left,
    required double top,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class Sparkles extends StatefulWidget {
  const Sparkles({
    super.key,
    this.count = 14,
    this.color = Colors.white,
  });

  final int count;
  final Color color;

  @override
  State<Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<Sparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SparkleSeed> _seeds;
  final Random _random = Random(28);

  @override
  void initState() {
    super.initState();
    _seeds = List<_SparkleSeed>.generate(
      widget.count,
      (index) => _SparkleSeed(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        durationFactor: 0.7 + _random.nextDouble() * 1.2,
        delayFactor: _random.nextDouble(),
        driftX: -10 + _random.nextDouble() * 20,
        driftY: -10 + _random.nextDouble() * 20,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: _seeds.map((seed) {
              final phase = (_controller.value + seed.delayFactor) % 1;
              final opacity = (sin(phase * pi * 2 * seed.durationFactor) + 1) / 2;
              final scale = 0.6 + opacity * 0.6;
              return Positioned(
                left: seed.x * size.width + sin(phase * pi * 2) * seed.driftX,
                top: seed.y * size.height + cos(phase * pi * 2) * seed.driftY,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: seed.size,
                    height: seed.size,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.05 + opacity * 0.9),
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.9),
                          blurRadius: seed.size * 1.4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SparkleSeed {
  const _SparkleSeed({
    required this.x,
    required this.y,
    required this.size,
    required this.durationFactor,
    required this.delayFactor,
    required this.driftX,
    required this.driftY,
  });

  final double x;
  final double y;
  final double size;
  final double durationFactor;
  final double delayFactor;
  final double driftX;
  final double driftY;
}

class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 32});

  final int count;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPieceData> _pieces;
  final Random _random = Random(72);
  static const List<Color> _palette = <Color>[
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFFBBF24),
  ];

  @override
  void initState() {
    super.initState();
    _pieces = List<_ConfettiPieceData>.generate(
      widget.count,
      (index) => _ConfettiPieceData(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.25,
        color: _palette[index % _palette.length],
        size: 8 + _random.nextDouble() * 10,
        duration: 0.6 + _random.nextDouble() * 0.4,
        rotateDirection: _random.nextBool() ? 1 : -1,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: _pieces.map((piece) {
              final raw = (_controller.value + piece.delay) % 1;
              final fall = Curves.easeIn.transform(raw.clamp(0, 1));
              final sway = sin(raw * pi * 4) * 30 * piece.rotateDirection;
              final rotation = raw * pi * 2 * piece.rotateDirection * 3;
              return Positioned(
                left: piece.x * size.width + sway,
                top: -40 + (size.height + 100) * fall,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: piece.size,
                    height: piece.size * 0.4,
                    decoration: BoxDecoration(
                      color: piece.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ConfettiPieceData {
  const _ConfettiPieceData({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
    required this.duration,
    required this.rotateDirection,
  });

  final double x;
  final double delay;
  final Color color;
  final double size;
  final double duration;
  final int rotateDirection;
}
