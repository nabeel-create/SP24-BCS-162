import 'dart:math';
import 'dart:ui';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../game_models.dart';
import '../theme/app_palette.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = 18,
    this.glowColor,
    this.borderRadius,
    this.style,
  });

  final Widget child;
  final double padding;
  final Color? glowColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? style;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final radius = borderRadius ?? colors.radius;
    return Container(
      margin: style,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                (glowColor ??
                        (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF9333EA)))
                    .withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.18,
                    ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.glassBg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.glassBorder),
            ),
            child: Padding(padding: EdgeInsets.all(padding), child: child),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.iconLeading = false,
    this.disabled = false,
    this.fullWidth = true,
    this.style,
  });

  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool iconLeading;
  final bool disabled;
  final bool fullWidth;
  final EdgeInsetsGeometry? style;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

enum ButtonVariant { primary, secondary, ghost, destructive, accent }

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null && widget.iconLeading) ...<Widget>[
          Icon(widget.icon, size: 20, color: _foreground(colors)),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _foreground(colors),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (widget.icon != null && !widget.iconLeading) ...<Widget>[
          const SizedBox(width: 10),
          Icon(widget.icon, size: 20, color: _foreground(colors)),
        ],
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: widget.disabled ? 0.5 : 1,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          margin: widget.style,
          decoration: widget.variant == ButtonVariant.primary
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(colors.radius),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                )
              : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(colors.radius),
              onTap: widget.disabled ? null : widget.onPressed,
              onHighlightChanged: (value) {
                setState(() {
                  _pressed = value;
                });
              },
              child: Ink(
                decoration: _decoration(colors),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Decoration _decoration(AppColors colors) {
    if (widget.variant == ButtonVariant.primary) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(colors.radius),
        gradient: LinearGradient(
          colors: <Color>[
            colors.gradientStart,
            colors.gradientMid,
            colors.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    Color background;
    switch (widget.variant) {
      case ButtonVariant.secondary:
        background = colors.secondary;
      case ButtonVariant.destructive:
        background = colors.destructive;
      case ButtonVariant.accent:
        background = colors.accent;
      case ButtonVariant.ghost:
        background = Colors.transparent;
      case ButtonVariant.primary:
        background = colors.primary;
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(colors.radius),
      color: background,
      border: widget.variant == ButtonVariant.ghost
          ? Border.all(color: colors.border)
          : null,
    );
  }

  Color _foreground(AppColors colors) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return colors.secondaryForeground;
      case ButtonVariant.destructive:
        return colors.destructiveForeground;
      case ButtonVariant.accent:
        return colors.accentForeground;
      case ButtonVariant.ghost:
        return colors.foreground;
    }
  }
}

class ArcadeTitle extends StatefulWidget {
  const ArcadeTitle({super.key, required this.text, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  State<ArcadeTitle> createState() => _ArcadeTitleState();
}

class _ArcadeTitleState extends State<ArcadeTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0A0A1F);
    final glowColor = isDark
        ? const Color(0xFFA78BFA)
        : const Color(0xFF7C3AED);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.55 + (_controller.value * 0.45);
        return Column(
          children: <Widget>[
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: 6,
                shadows: <Shadow>[
                  Shadow(
                    color: glowColor.withValues(alpha: opacity),
                    blurRadius: 16,
                  ),
                  Shadow(
                    color: glowColor.withValues(alpha: opacity * 0.8),
                    blurRadius: 32,
                  ),
                ],
              ),
            ),
            if (widget.subtitle != null) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _SubtitleLine(color: glowColor.withValues(alpha: 0.55)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0x8C0F0F23),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  _SubtitleLine(color: glowColor.withValues(alpha: 0.55)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final accent = tint ?? colors.primary;

    return GlassCard(
      padding: 12,
      glowColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.33)),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = max<double>(0.0, (constraints.maxWidth - 10) / 2);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Difficulty.values.map((difficulty) {
            final config = difficultyConfigs[difficulty]!;
            final meta = _difficultyMeta(difficulty);
            final selected = value == difficulty;
            return SizedBox(
              width: tileWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(colors.radius),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: meta.tint.withValues(alpha: 0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(colors.radius),
                    onTap: () => onChanged(difficulty),
                    child: Ink(
                      width: tileWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(colors.radius),
                        gradient: selected
                            ? LinearGradient(
                                colors: meta.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: selected ? null : colors.card,
                        border: selected
                            ? null
                            : Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 18,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : meta.tint.withValues(alpha: 0.13),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : meta.tint.withValues(alpha: 0.27),
                                ),
                              ),
                              child: Icon(
                                meta.icon,
                                size: 20,
                                color: selected ? Colors.white : meta.tint,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              config.label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : colors.foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${config.min}-${config.max}',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : colors.mutedForeground,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  FeatherIcons.target,
                                  size: 11,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : colors.mutedForeground,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${config.maxAttempts}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : colors.mutedForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  FeatherIcons.helpCircle,
                                  size: 11,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : colors.mutedForeground,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${config.hints}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : colors.mutedForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  _DifficultyMeta _difficultyMeta(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const _DifficultyMeta(
          icon: FeatherIcons.feather,
          tint: Color(0xFF10B981),
          gradient: <Color>[Color(0xFF10B981), Color(0xFF06B6D4)],
        );
      case Difficulty.medium:
        return const _DifficultyMeta(
          icon: FeatherIcons.zap,
          tint: Color(0xFFF59E0B),
          gradient: <Color>[Color(0xFFF59E0B), Color(0xFFEC4899)],
        );
      case Difficulty.hard:
        return const _DifficultyMeta(
          icon: FeatherIcons.shield,
          tint: Color(0xFFEF4444),
          gradient: <Color>[Color(0xFFEF4444), Color(0xFF7C3AED)],
        );
      case Difficulty.custom:
        return const _DifficultyMeta(
          icon: FeatherIcons.sliders,
          tint: Color(0xFF06B6D4),
          gradient: <Color>[Color(0xFF06B6D4), Color(0xFF8B5CF6)],
        );
    }
  }
}

class _DifficultyMeta {
  const _DifficultyMeta({
    required this.icon,
    required this.tint,
    required this.gradient,
  });

  final IconData icon;
  final Color tint;
  final List<Color> gradient;
}

class LivesBar extends StatefulWidget {
  const LivesBar({
    super.key,
    required this.total,
    required this.remaining,
    this.size = 14,
  });

  final int total;
  final int remaining;
  final double size;

  @override
  State<LivesBar> createState() => _LivesBarState();
}

class _LivesBarState extends State<LivesBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant LivesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.remaining == 1) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final tint = widget.remaining <= 1
        ? colors.destructive
        : widget.remaining <= (widget.total / 3).ceil()
        ? colors.warning
        : colors.destructive;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.remaining == 1
            ? 1 + (_pulseController.value * 0.18)
            : 1.0;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List<Widget>.generate(widget.total, (index) {
            final filled = index < widget.remaining;
            return Transform.scale(
              scale: filled && widget.remaining == 1 ? scale : 1,
              child: Icon(
                FeatherIcons.heart,
                size: widget.size,
                color: filled ? tint : colors.muted,
                shadows: filled
                    ? <Shadow>[
                        Shadow(
                          color: tint.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}

class HeatGauge extends StatelessWidget {
  const HeatGauge({super.key, required this.heat});

  final double heat;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final tint = _heatColor(heat);
    final label = _heatLabel(heat);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(FeatherIcons.thermometer, size: 13, color: tint),
                const SizedBox(width: 4),
                Text(
                  'Heat',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tint.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: tint.withValues(alpha: 0.9),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: tint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.04, end: heat.clamp(0.04, 1.0)),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: value, child: child),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF06B6D4),
                    Color(0xFF3B82F6),
                    Color(0xFFEAB308),
                    Color(0xFFF97316),
                    Color(0xFFEF4444),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Color _heatColor(double heat) {
    if (heat >= 0.85) {
      return const Color(0xFFEF4444);
    }
    if (heat >= 0.7) {
      return const Color(0xFFF97316);
    }
    if (heat >= 0.5) {
      return const Color(0xFFF59E0B);
    }
    if (heat >= 0.3) {
      return const Color(0xFFEAB308);
    }
    if (heat >= 0.15) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFF06B6D4);
  }

  static String _heatLabel(double heat) {
    if (heat <= 0) {
      return 'Take your shot';
    }
    if (heat >= 0.95) {
      return 'Bullseye';
    }
    if (heat >= 0.85) {
      return 'Burning';
    }
    if (heat >= 0.7) {
      return 'Hot';
    }
    if (heat >= 0.5) {
      return 'Warm';
    }
    if (heat >= 0.3) {
      return 'Cool';
    }
    if (heat >= 0.15) {
      return 'Cold';
    }
    return 'Freezing';
  }
}

class GuessRow extends StatefulWidget {
  const GuessRow({
    super.key,
    required this.guess,
    required this.index,
    required this.range,
  });

  final GuessRecord guess;
  final int index;
  final int range;

  @override
  State<GuessRow> createState() => _GuessRowState();
}

class _GuessRowState extends State<GuessRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final tint = proximityColor(
      widget.guess.distance,
      widget.range,
      colors.mutedForeground,
    );
    final label = proximityLabel(widget.guess.distance, widget.range);
    final direction = switch (widget.guess.outcome) {
      GuessOutcome.correct => FeatherIcons.checkCircle,
      GuessOutcome.tooHigh => FeatherIcons.arrowDown,
      GuessOutcome.tooLow => FeatherIcons.arrowUp,
    };
    final directionText = switch (widget.guess.outcome) {
      GuessOutcome.correct => 'Spot on',
      GuessOutcome.tooHigh => 'Too high',
      GuessOutcome.tooLow => 'Too low',
    };

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            ),
        child: GlassCard(
          padding: 14,
          glowColor: tint,
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: tint.withValues(alpha: 0.33)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: tint,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${widget.guess.value}',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Icon(direction, size: 13, color: tint),
                        const SizedBox(width: 4),
                        Text(
                          directionText,
                          style: TextStyle(
                            color: tint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tint.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tint,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: tint.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: tint,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color proximityColor(int distance, int range, Color fallback) {
  if (distance == 0) {
    return const Color(0xFF10B981);
  }
  final pct = distance / range;
  if (pct <= 0.05) {
    return const Color(0xFFEF4444);
  }
  if (pct <= 0.1) {
    return const Color(0xFFF97316);
  }
  if (pct <= 0.2) {
    return const Color(0xFFF59E0B);
  }
  if (pct <= 0.35) {
    return const Color(0xFFEAB308);
  }
  if (pct <= 0.55) {
    return const Color(0xFF3B82F6);
  }
  return fallback;
}

String proximityLabel(int distance, int range) {
  if (distance == 0) {
    return 'Bullseye';
  }
  final pct = distance / range;
  if (pct <= 0.05) {
    return 'Burning';
  }
  if (pct <= 0.1) {
    return 'Hot';
  }
  if (pct <= 0.2) {
    return 'Warm';
  }
  if (pct <= 0.35) {
    return 'Cool';
  }
  if (pct <= 0.55) {
    return 'Cold';
  }
  return 'Freezing';
}
