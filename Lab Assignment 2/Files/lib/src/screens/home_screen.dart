import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_controller.dart';
import '../game_models.dart';
import '../navigation.dart';
import '../theme/app_palette.dart';
import '../widgets/background_widgets.dart';
import '../widgets/game_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Difficulty _difficulty;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  late final AnimationController _heroController;
  late final AnimationController _flashController;
  late final AnimationController _shakeController;

  String? _error;
  String? _hintMessage;
  String? _guessFeedback;
  bool _showCelebrate = false;
  bool _navigatingToResult = false;
  double _displayScale = 1;
  Color _flashColor = Colors.transparent;
  int _customMin = 1;
  int _customMax = 300;
  int _customAttempts = 8;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.controller.settings.preferredDifficulty;
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _inputController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _inputController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _playerNameController.dispose();
    _inputFocusNode.dispose();
    _heroController.dispose();
    _flashController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    final filtered = _inputController.text.replaceAll(RegExp(r'[^0-9-]'), '');
    if (filtered != _inputController.text) {
      _inputController.value = _inputController.value.copyWith(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
      return;
    }
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
    _pulseDisplay();
  }

  void _pulseDisplay() {
    setState(() {
      _displayScale = 1.06;
    });
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _displayScale = 1;
        });
      }),
    );
  }

  Future<void> _runHaptic(Future<void> Function() action) async {
    if (widget.controller.settings.hapticsEnabled) {
      await action();
    }
  }

  Future<void> _handleStart() async {
    setState(() {
      _error = null;
      _hintMessage = null;
      _guessFeedback = null;
      _showCelebrate = false;
      _flashColor = Colors.transparent;
    });
    _inputController.clear();
    _inputFocusNode.unfocus();
    if (widget.controller.settings.preferredDifficulty != _difficulty) {
      await widget.controller.updateSettings(preferredDifficulty: _difficulty);
    }
    await _runHaptic(HapticFeedback.heavyImpact);
    widget.controller.startGame(
      _difficulty,
      customConfig: _difficulty == Difficulty.custom
          ? _buildCustomConfig()
          : null,
    );
  }

  DifficultyConfig _buildCustomConfig() {
    final minValue = min(_customMin, _customMax - 1);
    final maxValue = max(_customMax, minValue + 1);
    final range = maxValue - minValue;
    return DifficultyConfig(
      key: Difficulty.custom,
      label: 'Custom',
      min: minValue,
      max: maxValue,
      maxAttempts: _customAttempts,
      hints: 2,
      basePoints: max(150, min(900, 250 + (range ~/ 2))),
    );
  }

  Future<void> _handleAddPlayer() async {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'Enter player name';
      });
      _triggerShake();
      return;
    }
    await widget.controller.addPlayer(name);
    _playerNameController.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
    });
  }

  Future<void> _showPlayerSheet(BuildContext context) async {
    _playerNameController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final colors = paletteOf(context);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: GlassCard(
                padding: 16,
                glowColor: colors.primary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Players',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final player in widget.controller.players) ...<Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _PlayerAvatar(
                          initials: player.initials,
                          active:
                              player.id == widget.controller.activePlayer?.id,
                        ),
                        title: Text(
                          player.name,
                          style: TextStyle(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${widget.controller.history.where((game) => game.playerId == player.id).length} games',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (player.id == widget.controller.activePlayer?.id)
                              Icon(
                                FeatherIcons.check,
                                size: 18,
                                color: colors.success,
                              ),
                            IconButton(
                              tooltip: 'Edit player',
                              icon: Icon(
                                FeatherIcons.edit2,
                                size: 17,
                                color: colors.mutedForeground,
                              ),
                              onPressed: () => _showEditPlayerDialog(player),
                            ),
                            IconButton(
                              tooltip: 'Delete player',
                              icon: Icon(
                                FeatherIcons.trash2,
                                size: 17,
                                color: colors.destructive,
                              ),
                              onPressed: () => _confirmDeletePlayer(player),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await widget.controller.switchPlayer(player.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _playerNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) async {
                        await _handleAddPlayer();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'New player name',
                        prefixIcon: Icon(
                          FeatherIcons.userPlus,
                          size: 18,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Add Player',
                      icon: FeatherIcons.plus,
                      onPressed: () async {
                        await _handleAddPlayer();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPlayerDialog(PlayerProfile player) async {
    final colors = paletteOf(context);
    final controller = TextEditingController(text: player.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit player'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Player name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Save', style: TextStyle(color: colors.primary)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (nextName == null || nextName.trim().isEmpty) {
      return;
    }
    await widget.controller.editPlayer(player.id, nextName);
  }

  Future<void> _confirmDeletePlayer(PlayerProfile player) async {
    final colors = paletteOf(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${player.name}?'),
          content: const Text(
            'The player profile will be removed. Existing game history stays saved with this name.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: colors.destructive),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      await widget.controller.deletePlayer(player.id);
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  void _triggerFlash(Color color) {
    setState(() {
      _flashColor = color;
    });
    _flashController.forward(from: 0);
  }

  double get _shakeOffset {
    final value = _shakeController.value;
    if (value == 0 || value == 1) {
      return 0;
    }
    return sin(value * pi * 10) * 8 * (1 - value);
  }

  void _navigateToResult(Duration delay) {
    if (_navigatingToResult) {
      return;
    }
    _navigatingToResult = true;
    unawaited(
      Future<void>.delayed(delay, () async {
        if (!mounted) {
          return;
        }
        await Navigator.of(context).push(buildResultRoute(widget.controller));
        if (!mounted) {
          return;
        }
        setState(() {
          _navigatingToResult = false;
          _showCelebrate = false;
          _flashColor = Colors.transparent;
        });
      }),
    );
  }

  Future<void> _handleSubmit() async {
    final activeGame = widget.controller.activeGame;
    if (activeGame == null) {
      return;
    }

    setState(() {
      _error = null;
      _hintMessage = null;
      _guessFeedback = null;
    });

    final config = resolveDifficultyConfig(
      difficulty: activeGame.difficulty,
      customConfig: activeGame.customConfig,
    );
    final trimmed = _inputController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _error = 'Tap a number first';
      });
      _triggerShake();
      await _runHaptic(HapticFeedback.vibrate);
      return;
    }

    if (!RegExp(r'^-?\d+$').hasMatch(trimmed)) {
      setState(() {
        _error = 'Only whole numbers are allowed';
      });
      _triggerShake();
      await _runHaptic(HapticFeedback.vibrate);
      return;
    }

    final value = int.tryParse(trimmed);
    if (value == null || value < config.min || value > config.max) {
      setState(() {
        _error = 'Pick a number between ${config.min} and ${config.max}';
      });
      _triggerShake();
      _triggerFlash(paletteOf(context).destructive);
      await _runHaptic(HapticFeedback.vibrate);
      return;
    }

    if (activeGame.guesses.any((guess) => guess.value == value)) {
      setState(() {
        _error = 'Already tried $value';
      });
      _triggerShake();
      await _runHaptic(HapticFeedback.selectionClick);
      return;
    }

    final range = config.max - config.min;
    final palette = paletteOf(context);
    final result = widget.controller.submitGuess(value);
    _inputController.clear();

    if (result.finished) {
      if (result.record.outcome == GuessOutcome.correct) {
        await _runHaptic(HapticFeedback.lightImpact);
        _triggerFlash(palette.success);
        setState(() {
          _showCelebrate = true;
        });
        _navigateToResult(const Duration(milliseconds: 700));
      } else {
        await _runHaptic(HapticFeedback.vibrate);
        _triggerFlash(palette.destructive);
        _navigateToResult(const Duration(milliseconds: 250));
      }
      return;
    }

    final direction = result.record.outcome == GuessOutcome.tooHigh
        ? 'Too high'
        : 'Too low';
    setState(() {
      _guessFeedback =
          '$direction - try ${result.record.outcome == GuessOutcome.tooHigh ? 'lower' : 'higher'}';
    });

    final closeness = result.record.distance / range;
    if (closeness <= 0.1) {
      _triggerFlash(const Color(0xFFF97316));
      await _runHaptic(HapticFeedback.mediumImpact);
    } else {
      await _runHaptic(HapticFeedback.selectionClick);
    }
  }

  Future<void> _handleHint() async {
    final hint = widget.controller.useHint();
    if (hint == null) {
      setState(() {
        _hintMessage = 'No hints remaining';
      });
      return;
    }
    await _runHaptic(HapticFeedback.selectionClick);
    setState(() {
      _hintMessage = hint;
      _error = null;
      _guessFeedback = null;
    });
  }

  Future<void> _handleQuit() async {
    final colors = paletteOf(context);
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Give up?'),
          content: const Text('This will end the current game without saving.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Quit', style: TextStyle(color: colors.destructive)),
            ),
          ],
        );
      },
    );
    if (shouldQuit != true) {
      return;
    }
    widget.controller.abandonGame();
    _inputController.clear();
    setState(() {
      _error = null;
      _hintMessage = null;
      _showCelebrate = false;
      _flashColor = Colors.transparent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final activeGame = widget.controller.activeGame;
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: GradientBackground(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SafeArea(
                  bottom: false,
                  child: activeGame == null
                      ? (widget.controller.activePlayer == null
                            ? _buildPlayerStartScreen(context)
                            : _buildTitleScreen(context))
                      : _buildGameScreen(context, activeGame),
                ),
                if (_showCelebrate) const Confetti(count: 60),
                IgnorePointer(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.5, end: 0).animate(
                      CurvedAnimation(
                        parent: _flashController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: _flashColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerStartScreen(BuildContext context) {
    final colors = paletteOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 24),
          Center(
            child: AnimatedBuilder(
              animation: _heroController,
              builder: (context, child) {
                final value = _heroController.value;
                return Transform.translate(
                  offset: Offset(0, lerpDouble(0, -8, value)!),
                  child: const ArcadeTitle(
                    text: 'NUMERIX',
                    subtitle: 'add player to start',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Transform.translate(
            offset: Offset(_shakeOffset, 0),
            child: GlassCard(
              padding: 18,
              glowColor: colors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _PlayerAvatar(initials: 'P', active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Add player',
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your games and history will be saved by name.',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _playerNameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleAddPlayer(),
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Player name',
                      prefixIcon: Icon(
                        FeatherIcons.user,
                        size: 18,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: colors.destructive,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Continue',
                    icon: FeatherIcons.arrowRight,
                    onPressed: _handleAddPlayer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleScreen(BuildContext context) {
    final colors = paletteOf(context);
    final player = widget.controller.activePlayer;
    final history = widget.controller.activePlayerHistory;
    final wins = history.where((game) => game.status == GameStatus.won).length;
    final total = history.length;
    final winRate = total == 0 ? 0 : ((wins / total) * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.7),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: <Color>[
                            colors.gradientStart,
                            colors.gradientMid,
                            colors.gradientEnd,
                          ],
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.hash,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'v1.0',
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _IconButtonChip(
                icon: FeatherIcons.clock,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildHistoryRoute(widget.controller));
                },
              ),
            ],
          ),
          if (player != null) ...<Widget>[
            const SizedBox(height: 16),
            _PlayerStatusCard(
              player: player,
              games: total,
              wins: wins,
              winRate: winRate,
              players: widget.controller.players,
              onAdd: () => _showPlayerSheet(context),
              onSwitch: (id) => widget.controller.switchPlayer(id),
            ),
          ],
          const SizedBox(height: 26),
          Center(
            child: AnimatedBuilder(
              animation: _heroController,
              builder: (context, child) {
                final value = _heroController.value;
                final translateY = lerpDouble(0, -10, value)!;
                final angle = lerpDouble(-0.07, 0.07, value)!;
                final glowOpacity = 0.5 + (value * 0.5);
                return Column(
                  children: <Widget>[
                    SizedBox(
                      width: 220,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: glowOpacity * 0.45,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, translateY),
                            child: Transform.rotate(
                              angle: angle,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      colors.gradientStart,
                                      colors.gradientMid,
                                      colors.gradientEnd,
                                    ],
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: colors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    const Center(
                                      child: Text(
                                        '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 76,
                                          fontWeight: FontWeight.w700,
                                          height: 1.1,
                                          letterSpacing: -3,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 12,
                                      child: Container(
                                        width: 38,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.32,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                    ),
                    const ArcadeTitle(
                      text: 'NUMERIX',
                      subtitle: 'crack the code',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: <Widget>[
              Expanded(
                child: StatBadge(
                  icon: FeatherIcons.zap,
                  label: 'Streak',
                  value: '${widget.controller.streak.current}',
                  tint: colors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBadge(
                  icon: FeatherIcons.award,
                  label: 'Best',
                  value: '${widget.controller.streak.best}',
                  tint: colors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBadge(
                  icon: FeatherIcons.trendingUp,
                  label: 'Win %',
                  value: '$winRate',
                  tint: colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _SectionHeader(
            title: 'Choose your stage',
            hint: 'range \u2022 lives \u2022 hints',
          ),
          DifficultyPicker(
            value: _difficulty,
            onChanged: (difficulty) {
              setState(() {
                _difficulty = difficulty;
              });
            },
          ),
          if (_difficulty == Difficulty.custom) ...<Widget>[
            const SizedBox(height: 14),
            _CustomLevelCard(
              minValue: _customMin,
              maxValue: _customMax,
              attempts: _customAttempts,
              onMinChanged: (value) {
                setState(() {
                  _customMin = min(value, _customMax - 1);
                });
              },
              onMaxChanged: (value) {
                setState(() {
                  _customMax = max(value, _customMin + 1);
                });
              },
              onAttemptsChanged: (value) {
                setState(() {
                  _customAttempts = value;
                });
              },
            ),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'PLAY',
            icon: FeatherIcons.play,
            onPressed: _handleStart,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(buildHistoryRoute(widget.controller));
            },
            child: GlassCard(
              padding: 14,
              glowColor: colors.primary,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.33),
                      ),
                    ),
                    child: Icon(
                      FeatherIcons.trendingUp,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Past games',
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total == 0
                              ? 'No games yet - your history will appear here'
                              : '$total game${total == 1 ? '' : 's'} \u2022 $wins won',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    FeatherIcons.chevronRight,
                    size: 18,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, ActiveGame activeGame) {
    final colors = paletteOf(context);
    final config = resolveDifficultyConfig(
      difficulty: activeGame.difficulty,
      customConfig: activeGame.customConfig,
    );
    final range = config.max - config.min;
    final attemptsLeft = config.maxAttempts - activeGame.attempts;
    final hintsLeft = config.hints - activeGame.hintsUsed;
    final closestDistance = activeGame.guesses.isEmpty
        ? null
        : activeGame.guesses
              .map((guess) => guess.distance)
              .reduce((left, right) => left < right ? left : right);
    final heat = closestDistance == null
        ? 0.0
        : max<double>(0.0, 1 - closestDistance / max(1, range));

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.9),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stage ${difficultyKey(activeGame.difficulty)} \u2022 ${config.min}-${config.max}',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _handleQuit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.destructive.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.destructive.withValues(alpha: 0.33),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(FeatherIcons.x, size: 14, color: colors.destructive),
                      const SizedBox(width: 4),
                      Text(
                        'Quit',
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              children: <Widget>[
                GlassCard(
                  padding: 14,
                  glowColor: colors.destructive,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Lives',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 1),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: colors.foreground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: <TextSpan>[
                                  TextSpan(text: '$attemptsLeft'),
                                  TextSpan(
                                    text: ' / ${config.maxAttempts}',
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      LivesBar(
                        total: config.maxAttempts,
                        remaining: attemptsLeft,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(padding: 14, child: HeatGauge(heat: heat)),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(_shakeOffset, 0),
                  child: GlassCard(
                    padding: 20,
                    glowColor: _error == null
                        ? colors.primary
                        : colors.destructive,
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Your guess',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedScale(
                          scale: _displayScale,
                          duration: const Duration(milliseconds: 110),
                          child: TextField(
                            controller: _inputController,
                            focusNode: _inputFocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.go,
                            maxLength: 5,
                            onSubmitted: (_) => _handleSubmit(),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[-0-9]'),
                              ),
                            ],
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 84,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -3,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '?',
                              hintStyle: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0x2E0F0F23),
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                          ),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.destructive.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.destructive.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  FeatherIcons.alertCircle,
                                  size: 13,
                                  color: colors.destructive,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.destructive,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_guessFeedback != null) ...<Widget>[
                          const SizedBox(height: 8),
                          _GuessFeedbackPill(
                            text: _guessFeedback!,
                            outcome: activeGame.guesses.isEmpty
                                ? GuessOutcome.tooLow
                                : activeGame.guesses.last.outcome,
                          ),
                        ] else if (_hintMessage != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.33),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  FeatherIcons.zap,
                                  size: 13,
                                  color: colors.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hintMessage!,
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (activeGame.guesses.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          _GuessSnackList(guesses: activeGame.guesses),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: hintsLeft <= 0 ? null : _handleHint,
                  child: Opacity(
                    opacity: hintsLeft <= 0 ? 0.8 : 1,
                    child: GlassCard(
                      padding: 12,
                      glowColor: hintsLeft > 0
                          ? colors.accent
                          : colors.mutedForeground,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  (hintsLeft > 0
                                          ? colors.accent
                                          : colors.mutedForeground)
                                      .withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (hintsLeft > 0
                                            ? colors.accent
                                            : colors.mutedForeground)
                                        .withValues(alpha: 0.40),
                              ),
                            ),
                            child: Icon(
                              FeatherIcons.zap,
                              size: 16,
                              color: hintsLeft > 0
                                  ? colors.accent
                                  : colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Reveal a hint',
                                  style: TextStyle(
                                    color: hintsLeft > 0
                                        ? colors.foreground
                                        : colors.mutedForeground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  hintsLeft > 0
                                      ? '$hintsLeft hint${hintsLeft == 1 ? '' : 's'} remaining'
                                      : 'All hints used',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List<Widget>.generate(config.hints, (
                              index,
                            ) {
                              final used = index >= hintsLeft;
                              final dotColor = used
                                  ? colors.muted
                                  : colors.accent;
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 4,
                                ),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    boxShadow: used
                                        ? const <BoxShadow>[]
                                        : <BoxShadow>[
                                            BoxShadow(
                                              color: dotColor.withValues(
                                                alpha: 0.7,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Submit Guess',
                  icon: FeatherIcons.send,
                  onPressed: _handleSubmit,
                  disabled: _inputController.text.trim().isEmpty,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Your guesses',
                  hint: '${activeGame.guesses.length} of ${config.maxAttempts}',
                ),
                if (activeGame.guesses.isEmpty)
                  GlassCard(
                    padding: 20,
                    child: Column(
                      children: <Widget>[
                        Icon(
                          FeatherIcons.zap,
                          size: 20,
                          color: colors.mutedForeground,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make your first guess to see high/low feedback',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: <Widget>[
                      for (
                        int index = activeGame.guesses.length - 1;
                        index >= 0;
                        index--
                      ) ...<Widget>[
                        GuessRow(
                          guess: activeGame.guesses[index],
                          index: index,
                          range: range,
                        ),
                        if (index != 0) const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerStatusCard extends StatelessWidget {
  const _PlayerStatusCard({
    required this.player,
    required this.games,
    required this.wins,
    required this.winRate,
    required this.players,
    required this.onAdd,
    required this.onSwitch,
  });

  final PlayerProfile player;
  final int games;
  final int wins;
  final int winRate;
  final List<PlayerProfile> players;
  final VoidCallback onAdd;
  final ValueChanged<String> onSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return GlassCard(
      padding: 14,
      glowColor: colors.primary,
      child: Row(
        children: <Widget>[
          _PlayerAvatar(initials: player.initials, active: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$games game${games == 1 ? '' : 's'} - $wins wins - $winRate%',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(FeatherIcons.users, size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${players.length}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.initials, required this.active});

  final String initials;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: active
              ? <Color>[colors.gradientStart, colors.gradientMid]
              : <Color>[colors.card, colors.muted],
        ),
        border: Border.all(
          color: active
              ? colors.primary.withValues(alpha: 0.45)
              : colors.border,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: active ? Colors.white : colors.foreground,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CustomLevelCard extends StatelessWidget {
  const _CustomLevelCard({
    required this.minValue,
    required this.maxValue,
    required this.attempts,
    required this.onMinChanged,
    required this.onMaxChanged,
    required this.onAttemptsChanged,
  });

  final int minValue;
  final int maxValue;
  final int attempts;
  final ValueChanged<int> onMinChanged;
  final ValueChanged<int> onMaxChanged;
  final ValueChanged<int> onAttemptsChanged;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return GlassCard(
      padding: 14,
      glowColor: colors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(FeatherIcons.sliders, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'Custom range',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$minValue-$maxValue',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CustomSliderRow(
            label: 'Min',
            value: minValue,
            min: 0,
            max: 999,
            onChanged: onMinChanged,
          ),
          _CustomSliderRow(
            label: 'Max',
            value: maxValue,
            min: 1,
            max: 1000,
            onChanged: onMaxChanged,
          ),
          _CustomSliderRow(
            label: 'Lives',
            value: attempts,
            min: 3,
            max: 15,
            onChanged: onAttemptsChanged,
          ),
        ],
      ),
    );
  }
}

class _CustomSliderRow extends StatelessWidget {
  const _CustomSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuessFeedbackPill extends StatelessWidget {
  const _GuessFeedbackPill({required this.text, required this.outcome});

  final String text;
  final GuessOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final isHigh = outcome == GuessOutcome.tooHigh;
    final tint = isHigh ? colors.destructive : colors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isHigh ? FeatherIcons.arrowDown : FeatherIcons.arrowUp,
            size: 14,
            color: tint,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuessSnackList extends StatelessWidget {
  const _GuessSnackList({required this.guesses});

  final List<GuessRecord> guesses;

  @override
  Widget build(BuildContext context) {
    final recent = guesses.length > 5
        ? guesses.sublist(guesses.length - 5)
        : guesses;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int index = 0; index < recent.length; index++) ...<Widget>[
            _GuessSnackChip(guess: recent[index]),
            if (index != recent.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _GuessSnackChip extends StatelessWidget {
  const _GuessSnackChip({required this.guess});

  final GuessRecord guess;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final tint = switch (guess.outcome) {
      GuessOutcome.correct => colors.success,
      GuessOutcome.tooHigh => colors.destructive,
      GuessOutcome.tooLow => colors.info,
    };
    final icon = switch (guess.outcome) {
      GuessOutcome.correct => FeatherIcons.check,
      GuessOutcome.tooHigh => FeatherIcons.arrowDown,
      GuessOutcome.tooLow => FeatherIcons.arrowUp,
    };
    final label = switch (guess.outcome) {
      GuessOutcome.correct => 'OK',
      GuessOutcome.tooHigh => 'High',
      GuessOutcome.tooLow => 'Low',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${guess.value}',
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonChip extends StatelessWidget {
  const _IconButtonChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 18, color: colors.foreground),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Text(
            hint,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
