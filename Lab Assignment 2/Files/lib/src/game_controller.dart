import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_models.dart';
import 'game_storage.dart' as storage;

class GameController extends ChangeNotifier {
  final Random _random = Random();

  List<GameRecord> history = <GameRecord>[];
  List<PlayerProfile> players = <PlayerProfile>[];
  String? activePlayerId;
  StreakData streak = StreakData.defaults;
  SettingsData settings = SettingsData.defaults;
  ActiveGame? activeGame;
  GameRecord? lastGame;
  bool loading = true;

  PlayerProfile? get activePlayer {
    for (final player in players) {
      if (player.id == activePlayerId) {
        return player;
      }
    }
    return players.isEmpty ? null : players.first;
  }

  List<GameRecord> get activePlayerHistory {
    final player = activePlayer;
    if (player == null) {
      return history;
    }
    return history.where((game) => game.playerId == player.id).toList();
  }

  Future<void> initialize() async {
    try {
      final results = await Future.wait<dynamic>([
        storage.loadHistory(),
        storage.loadStreak(),
        storage.loadSettings(),
        storage.loadPlayers(),
        storage.loadActivePlayerId(),
      ]);
      history = results[0] as List<GameRecord>;
      streak = results[1] as StreakData;
      settings = results[2] as SettingsData;
      players = results[3] as List<PlayerProfile>;
      activePlayerId = results[4] as String?;
      if (activePlayerId == null && players.isNotEmpty) {
        activePlayerId = players.first.id;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PlayerProfile> addPlayer(String name) async {
    final trimmed = name.trim().isEmpty
        ? 'Player ${players.length + 1}'
        : name.trim();
    final player = PlayerProfile(
      id: generateId(_random),
      name: trimmed,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    players = <PlayerProfile>[...players, player];
    activePlayerId = player.id;
    notifyListeners();
    await Future.wait<void>([
      storage.savePlayers(players),
      storage.saveActivePlayerId(activePlayerId),
    ]);
    return player;
  }

  Future<void> switchPlayer(String id) async {
    if (!players.any((player) => player.id == id)) {
      return;
    }
    activePlayerId = id;
    notifyListeners();
    await storage.saveActivePlayerId(activePlayerId);
  }

  Future<void> editPlayer(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    players = players
        .map(
          (player) => player.id == id
              ? PlayerProfile(
                  id: player.id,
                  name: trimmed,
                  createdAt: player.createdAt,
                )
              : player,
        )
        .toList();
    history = history
        .map(
          (game) => game.playerId == id
              ? GameRecord(
                  id: game.id,
                  difficulty: game.difficulty,
                  target: game.target,
                  attempts: game.attempts,
                  maxAttempts: game.maxAttempts,
                  status: game.status,
                  score: game.score,
                  guesses: game.guesses,
                  startedAt: game.startedAt,
                  finishedAt: game.finishedAt,
                  hintsUsed: game.hintsUsed,
                  playerId: game.playerId,
                  playerName: trimmed,
                  customConfig: game.customConfig,
                )
              : game,
        )
        .toList();
    notifyListeners();
    await Future.wait<void>([
      storage.savePlayers(players),
      storage.saveHistory(history),
    ]);
  }

  Future<void> deletePlayer(String id) async {
    players = players.where((player) => player.id != id).toList();
    if (activePlayerId == id) {
      activePlayerId = players.isEmpty ? null : players.first.id;
    }
    notifyListeners();
    await Future.wait<void>([
      storage.savePlayers(players),
      storage.saveActivePlayerId(activePlayerId),
    ]);
  }

  void startGame(Difficulty difficulty, {DifficultyConfig? customConfig}) {
    final config = resolveDifficultyConfig(
      difficulty: difficulty,
      customConfig: customConfig,
    );
    activeGame = ActiveGame(
      id: generateId(_random),
      difficulty: difficulty,
      target: generateTarget(config, _random),
      attempts: 0,
      guesses: const <GuessRecord>[],
      hintsUsed: 0,
      startedAt: DateTime.now().millisecondsSinceEpoch,
      customConfig: difficulty == Difficulty.custom ? config : null,
    );
    notifyListeners();
  }

  SubmitGuessResult submitGuess(int value) {
    final game = activeGame;
    if (game == null) {
      throw StateError('No active game');
    }

    final config = resolveDifficultyConfig(
      difficulty: game.difficulty,
      customConfig: game.customConfig,
    );
    final outcome = evaluateGuess(value, game.target);
    final guessRecord = GuessRecord(
      value: value,
      outcome: outcome,
      distance: (value - game.target).abs(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final nextAttempts = game.attempts + 1;
    final nextGuesses = <GuessRecord>[...game.guesses, guessRecord];
    final won = outcome == GuessOutcome.correct;
    final outOfAttempts = nextAttempts >= config.maxAttempts;
    final finished = won || outOfAttempts;

    final nextGame = game.copyWith(
      attempts: nextAttempts,
      guesses: nextGuesses,
    );

    if (!finished) {
      activeGame = nextGame;
      notifyListeners();
      return SubmitGuessResult(record: guessRecord, finished: false);
    }

    final finishedRecord = GameRecord(
      id: nextGame.id,
      difficulty: nextGame.difficulty,
      target: nextGame.target,
      attempts: nextAttempts,
      maxAttempts: config.maxAttempts,
      status: won ? GameStatus.won : GameStatus.lost,
      score: calculateScore(config, nextAttempts, nextGame.hintsUsed, won),
      guesses: nextGuesses,
      startedAt: nextGame.startedAt,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
      hintsUsed: nextGame.hintsUsed,
      playerId: activePlayer?.id ?? '',
      playerName: activePlayer?.name ?? 'Player',
      customConfig: nextGame.customConfig,
    );

    history = <GameRecord>[finishedRecord, ...history].take(200).toList();
    streak = won
        ? StreakData(
            current: streak.current + 1,
            best: max(streak.best, streak.current + 1),
            lastWonAt: DateTime.now().millisecondsSinceEpoch,
          )
        : streak.copyWith(current: 0);
    lastGame = finishedRecord;
    activeGame = null;
    notifyListeners();

    unawaited(_persistFinishedGame());

    return SubmitGuessResult(
      record: guessRecord,
      finished: true,
      finishedRecord: finishedRecord,
    );
  }

  String? useHint() {
    final game = activeGame;
    if (game == null) {
      return null;
    }

    final config = resolveDifficultyConfig(
      difficulty: game.difficulty,
      customConfig: game.customConfig,
    );
    if (game.hintsUsed >= config.hints) {
      return null;
    }

    activeGame = game.copyWith(hintsUsed: game.hintsUsed + 1);
    notifyListeners();
    return getHint(
      game.target,
      min: config.min,
      max: config.max,
      random: _random,
    );
  }

  void abandonGame() {
    activeGame = null;
    notifyListeners();
  }

  Future<void> deleteSavedGame(String id) async {
    history = history.where((game) => game.id != id).toList();
    notifyListeners();
    await storage.saveHistory(history);
  }

  Future<void> clearSavedHistory() async {
    history = <GameRecord>[];
    notifyListeners();
    await storage.clearHistory();
  }

  Future<void> clearActivePlayerHistory() async {
    final player = activePlayer;
    if (player == null) {
      await clearSavedHistory();
      return;
    }
    history = history.where((game) => game.playerId != player.id).toList();
    notifyListeners();
    await storage.saveHistory(history);
  }

  Future<void> updateSettings({
    Difficulty? preferredDifficulty,
    bool? hapticsEnabled,
  }) async {
    settings = settings.copyWith(
      preferredDifficulty: preferredDifficulty,
      hapticsEnabled: hapticsEnabled,
    );
    notifyListeners();
    await storage.saveSettings(settings);
  }

  void setLastGame(GameRecord? game) {
    lastGame = game;
    notifyListeners();
  }

  Future<void> _persistFinishedGame() async {
    await storage.saveHistory(history);
    await storage.saveStreak(streak);
  }
}
