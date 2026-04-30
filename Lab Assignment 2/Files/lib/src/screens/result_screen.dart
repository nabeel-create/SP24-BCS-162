import 'dart:math';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../game_models.dart';
import '../navigation.dart';
import '../theme/app_palette.dart';
import '../widgets/background_widgets.dart';
import '../widgets/game_widgets.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final lastGame = widget.controller.lastGame;
    if (lastGame == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'No recent game',
                    style: TextStyle(
                      color: paletteOf(context).foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Back to home',
                    icon: FeatherIcons.home,
                    iconLeading: true,
                    onPressed: _goHome,
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final colors = paletteOf(context);
    final won = lastGame.status == GameStatus.won;
    final config = resolveDifficultyConfig(
      difficulty: lastGame.difficulty,
      customConfig: lastGame.customConfig,
    );
    final duration = max(
      1,
      ((lastGame.finishedAt - lastGame.startedAt) / 1000).round(),
    );
    final closest = lastGame.guesses.isEmpty
        ? 0
        : lastGame.guesses
              .map((guess) => guess.distance)
              .reduce((left, right) => left < right ? left : right);
    final accent = won ? colors.success : colors.destructive;
    final targetGradient = won
        ? const <Color>[Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF7C3AED)]
        : <Color>[colors.gradientStart, colors.gradientMid, colors.gradientEnd];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        variant: won ? BackgroundVariant.win : BackgroundVariant.lose,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (won) const Confetti(count: 60),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _ResultIconButton(icon: FeatherIcons.x, onTap: _goHome),
                        const Spacer(),
                        _ResultIconButton(
                          icon: FeatherIcons.clock,
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              buildHistoryRoute(widget.controller),
                            );
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        child: Column(
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final ringScale = 1 + (_controller.value * 0.5);
                                final ringOpacity = max<double>(
                                  0.0,
                                  0.6 - (_controller.value * 0.6),
                                );
                                final medalScale = Curves.elasticOut.transform(
                                  _controller.value.clamp(0.0, 1.0),
                                );
                                return Column(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Transform.scale(
                                            scale: ringScale,
                                            child: Opacity(
                                              opacity: ringOpacity,
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: accent,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: medalScale,
                                            child: Container(
                                              width: 90,
                                              height: 90,
                                              decoration: BoxDecoration(
                                                color: accent.withValues(
                                                  alpha: 0.13,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accent,
                                                  width: 2,
                                                ),
                                                boxShadow: <BoxShadow>[
                                                  BoxShadow(
                                                    color: accent.withValues(
                                                      alpha: 0.6,
                                                    ),
                                                    blurRadius: 24,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                won
                                                    ? FeatherIcons.award
                                                    : FeatherIcons.xCircle,
                                                size: 48,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      won ? 'Victory!' : 'Game over',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      won
                                          ? 'Cracked it in ${lastGame.attempts} ${lastGame.attempts == 1 ? 'try' : 'tries'}'
                                          : 'You used all ${lastGame.maxAttempts} tries',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  colors.radius + 8,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  colors.radius + 8,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: targetGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 36,
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'The number was',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        AnimatedBuilder(
                                          animation: _controller,
                                          builder: (context, child) {
                                            final scale =
                                                0.5 +
                                                Curves.elasticOut.transform(
                                                      _controller.value.clamp(
                                                        0.0,
                                                        1.0,
                                                      ),
                                                    ) *
                                                    0.65;
                                            return Transform.scale(
                                              scale: scale,
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            '${lastGame.target}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 96,
                                              fontWeight: FontWeight.w700,
                                              height: 1.1,
                                              letterSpacing: -4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.22,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.30,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Icon(
                                                FeatherIcons.zap,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${config.label} \u2022 ${config.min}-${config.max}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final tileWidth =
                                    (constraints.maxWidth - 20) / 3;
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: <Widget>[
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.award,
                                      label: 'Score',
                                      value: '${lastGame.score}',
                                      tint: colors.accent,
                                    ),
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.target,
                                      label: 'Tries',
                                      value:
                                          '${lastGame.attempts}/${lastGame.maxAttempts}',
                                      tint: colors.primary,
                                    ),
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.zap,
                                      label: 'Closest',
                                      value: closest == 0
                                          ? 'Bullseye'
                                          : '+/-$closest',
                                      tint: colors.warning,
                                    ),
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.clock,
                                      label: 'Time',
                                      value: '${duration}s',
                                      tint: colors.info,
                                    ),
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.helpCircle,
                                      label: 'Hints',
                                      value:
                                          '${lastGame.hintsUsed}/${config.hints}',
                                      tint: colors.mutedForeground,
                                    ),
                                    _StatTile(
                                      width: tileWidth,
                                      icon: FeatherIcons.trendingUp,
                                      label: 'Streak',
                                      value:
                                          '${widget.controller.streak.current}',
                                      tint: colors.success,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            PrimaryButton(
                              label: 'Play again',
                              icon: FeatherIcons.rotateCcw,
                              iconLeading: true,
                              onPressed: () {
                                widget.controller.startGame(
                                  lastGame.difficulty,
                                );
                                _goHome();
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Home',
                                    variant: ButtonVariant.secondary,
                                    icon: FeatherIcons.home,
                                    iconLeading: true,
                                    fullWidth: true,
                                    onPressed: _goHome,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'History',
                                    variant: ButtonVariant.ghost,
                                    icon: FeatherIcons.clock,
                                    iconLeading: true,
                                    fullWidth: true,
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        buildHistoryRoute(widget.controller),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

class _ResultIconButton extends StatelessWidget {
  const _ResultIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 18, color: colors.foreground),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return SizedBox(
      width: width,
      child: GlassCard(
        padding: 14,
        glowColor: tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.20),
                shape: BoxShape.circle,
                border: Border.all(color: tint.withValues(alpha: 0.33)),
              ),
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
