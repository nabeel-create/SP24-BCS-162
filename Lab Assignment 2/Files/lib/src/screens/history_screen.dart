import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_controller.dart';
import '../game_models.dart';
import '../theme/app_palette.dart';
import '../widgets/background_widgets.dart';
import '../widgets/game_widgets.dart';

enum HistoryFilter { all, won, easy, medium, hard, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;

  Future<void> _runHaptic(Future<void> Function() action) async {
    if (widget.controller.settings.hapticsEnabled) {
      await action();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final colors = paletteOf(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete game?'),
          content: const Text('This entry will be removed from history.'),
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

    if (shouldDelete != true) {
      return;
    }
    await _runHaptic(HapticFeedback.selectionClick);
    await widget.controller.deleteSavedGame(id);
  }

  Future<void> _confirmClearAll() async {
    if (widget.controller.activePlayerHistory.isEmpty) {
      return;
    }
    final colors = paletteOf(context);
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear player history?'),
          content: const Text(
            'Only the active player history will be deleted.',
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
              child: Text('Clear', style: TextStyle(color: colors.destructive)),
            ),
          ],
        );
      },
    );
    if (shouldClear != true) {
      return;
    }
    await _runHaptic(HapticFeedback.selectionClick);
    await widget.controller.clearActivePlayerHistory();
  }

  List<GameRecord> _filteredHistory(List<GameRecord> history) {
    switch (_filter) {
      case HistoryFilter.all:
        return history;
      case HistoryFilter.won:
        return history.where((game) => game.status == GameStatus.won).toList();
      case HistoryFilter.easy:
        return history
            .where((game) => game.difficulty == Difficulty.easy)
            .toList();
      case HistoryFilter.medium:
        return history
            .where((game) => game.difficulty == Difficulty.medium)
            .toList();
      case HistoryFilter.hard:
        return history
            .where((game) => game.difficulty == Difficulty.hard)
            .toList();
      case HistoryFilter.custom:
        return history
            .where((game) => game.difficulty == Difficulty.custom)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final colors = paletteOf(context);
        final player = widget.controller.activePlayer;
        final history = widget.controller.activePlayerHistory;
        final filterChips = _filterChips();
        final filtered = _filteredHistory(history);
        final wins = history
            .where((game) => game.status == GameStatus.won)
            .length;
        final winRate = history.isEmpty
            ? 0
            : ((wins / history.length) * 100).round();
        final best = history
            .where((game) => game.status == GameStatus.won)
            .fold<int>(
              0,
              (maxScore, game) => game.score > maxScore ? game.score : maxScore,
            );
        final fewest = history
            .where((game) => game.status == GameStatus.won)
            .fold<int?>(null, (current, game) {
              if (current == null || game.attempts < current) {
                return game.attempts;
              }
              return current;
            });

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                    child: Row(
                      children: <Widget>[
                        _HistoryIconButton(
                          icon: FeatherIcons.arrowLeft,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(
                                'History',
                                style: TextStyle(
                                  color: colors.foreground,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                player == null
                                    ? '${history.length} game${history.length == 1 ? '' : 's'} saved'
                                    : '${player.name} - ${history.length} game${history.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: colors.mutedForeground,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _HistoryIconButton(
                          icon: FeatherIcons.trash2,
                          color: colors.destructive,
                          opacity: history.isEmpty ? 0.4 : 1,
                          onTap: _confirmClearAll,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: StatBadge(
                                  icon: FeatherIcons.award,
                                  label: 'Best score',
                                  value: best == 0 ? '-' : '$best',
                                  tint: colors.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatBadge(
                                  icon: FeatherIcons.target,
                                  label: 'Win rate',
                                  value: '$winRate%',
                                  tint: colors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: StatBadge(
                                  icon: FeatherIcons.zap,
                                  label: 'Best streak',
                                  value: '${widget.controller.streak.best}',
                                  tint: colors.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatBadge(
                                  icon: FeatherIcons.trendingUp,
                                  label: 'Fewest tries',
                                  value: fewest == null ? '-' : '$fewest',
                                  tint: colors.info,
                                ),
                              ),
                            ],
                          ),
                          if (history.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 18),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: <Widget>[
                                  for (
                                    int index = 0;
                                    index < filterChips.length;
                                    index++
                                  ) ...<Widget>[
                                    _FilterChip(
                                      label: filterChips[index].label,
                                      active:
                                          _filter == filterChips[index].filter,
                                      onTap: () {
                                        setState(() {
                                          _filter = filterChips[index].filter;
                                        });
                                      },
                                    ),
                                    if (index != filterChips.length - 1)
                                      const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (filtered.isEmpty)
                            GlassCard(
                              padding: 28,
                              glowColor: colors.primary,
                              child: Center(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(
                                          alpha: 0.13,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.primary.withValues(
                                            alpha: 0.33,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        FeatherIcons.inbox,
                                        size: 28,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      history.isEmpty
                                          ? 'No games yet'
                                          : 'Nothing matches this filter',
                                      style: TextStyle(
                                        color: colors.foreground,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      history.isEmpty
                                          ? 'Start your first game and your results will be saved here automatically.'
                                          : 'Try switching to a different filter to see your other games.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (history.isEmpty) ...<Widget>[
                                      const SizedBox(height: 18),
                                      PrimaryButton(
                                        label: 'Start a game',
                                        icon: FeatherIcons.play,
                                        iconLeading: true,
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                        },
                                        fullWidth: false,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: <Widget>[
                                for (
                                  int index = 0;
                                  index < filtered.length;
                                  index++
                                ) ...<Widget>[
                                  _HistoryItem(
                                    game: filtered[index],
                                    onDelete: () =>
                                        _confirmDelete(filtered[index].id),
                                  ),
                                  if (index != filtered.length - 1)
                                    const SizedBox(height: 12),
                                ],
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
        );
      },
    );
  }

  List<_FilterChipData> _filterChips() {
    return const <_FilterChipData>[
      _FilterChipData(filter: HistoryFilter.all, label: 'All'),
      _FilterChipData(filter: HistoryFilter.won, label: 'Wins'),
      _FilterChipData(filter: HistoryFilter.easy, label: 'Easy'),
      _FilterChipData(filter: HistoryFilter.medium, label: 'Medium'),
      _FilterChipData(filter: HistoryFilter.hard, label: 'Hard'),
      _FilterChipData(filter: HistoryFilter.custom, label: 'Custom'),
    ];
  }
}

class _FilterChipData {
  const _FilterChipData({required this.filter, required this.label});

  final HistoryFilter filter;
  final String label;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: active
                  ? LinearGradient(
                      colors: <Color>[colors.gradientStart, colors.gradientMid],
                    )
                  : null,
              color: active ? null : colors.card,
              border: active ? null : Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : colors.foreground,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryIconButton extends StatelessWidget {
  const _HistoryIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.opacity = 1,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    return Opacity(
      opacity: opacity,
      child: Material(
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
            child: Icon(icon, size: 18, color: color ?? colors.foreground),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.game, required this.onDelete});

  final GameRecord game;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = paletteOf(context);
    final won = game.status == GameStatus.won;
    final tint = won ? colors.success : colors.destructive;
    final diffTint = switch (game.difficulty) {
      Difficulty.easy => colors.success,
      Difficulty.medium => colors.warning,
      Difficulty.hard => colors.destructive,
      Difficulty.custom => colors.info,
    };
    final config = resolveDifficultyConfig(
      difficulty: game.difficulty,
      customConfig: game.customConfig,
    );

    return GlassCard(
      padding: 14,
      glowColor: tint,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: tint),
            ),
            child: Icon(
              won ? FeatherIcons.check : FeatherIcons.x,
              size: 20,
              color: tint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      won ? 'Won' : 'Lost',
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: diffTint.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: diffTint.withValues(alpha: 0.33),
                        ),
                      ),
                      child: Text(
                        config.label,
                        style: TextStyle(
                          color: diffTint,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.playerName} - Target ${game.target} - ${game.attempts}/${game.maxAttempts} tries',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRelativeTime(game.finishedAt),
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${game.score}',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    FeatherIcons.trash2,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatRelativeTime(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  if (date.year == now.year) {
    return '$month ${date.day}';
  }
  return '$month ${date.day}, ${date.year}';
}
