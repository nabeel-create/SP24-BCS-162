import 'dart:math';

enum Difficulty { easy, medium, hard, custom }

enum GameStatus { won, lost, inProgress }

enum GuessOutcome { correct, tooHigh, tooLow }

class DifficultyConfig {
  const DifficultyConfig({
    required this.key,
    required this.label,
    required this.min,
    required this.max,
    required this.maxAttempts,
    required this.hints,
    required this.basePoints,
  });

  final Difficulty key;
  final String label;
  final int min;
  final int max;
  final int maxAttempts;
  final int hints;
  final int basePoints;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'min': min,
      'max': max,
      'maxAttempts': maxAttempts,
      'hints': hints,
      'basePoints': basePoints,
    };
  }

  factory DifficultyConfig.fromJson(Map<String, dynamic> json, Difficulty key) {
    return DifficultyConfig(
      key: key,
      label: json['label'] as String? ?? 'Custom',
      min: json['min'] as int? ?? 1,
      max: json['max'] as int? ?? 100,
      maxAttempts: json['maxAttempts'] as int? ?? 8,
      hints: json['hints'] as int? ?? 2,
      basePoints: json['basePoints'] as int? ?? 300,
    );
  }
}

const Map<Difficulty, DifficultyConfig> difficultyConfigs = {
  Difficulty.easy: DifficultyConfig(
    key: Difficulty.easy,
    label: 'Easy',
    min: 1,
    max: 50,
    maxAttempts: 10,
    hints: 3,
    basePoints: 100,
  ),
  Difficulty.medium: DifficultyConfig(
    key: Difficulty.medium,
    label: 'Medium',
    min: 1,
    max: 100,
    maxAttempts: 8,
    hints: 2,
    basePoints: 250,
  ),
  Difficulty.hard: DifficultyConfig(
    key: Difficulty.hard,
    label: 'Hard',
    min: 1,
    max: 200,
    maxAttempts: 7,
    hints: 1,
    basePoints: 500,
  ),
  Difficulty.custom: DifficultyConfig(
    key: Difficulty.custom,
    label: 'Custom',
    min: 1,
    max: 300,
    maxAttempts: 8,
    hints: 2,
    basePoints: 350,
  ),
};

DifficultyConfig resolveDifficultyConfig({
  required Difficulty difficulty,
  DifficultyConfig? customConfig,
}) {
  if (difficulty == Difficulty.custom && customConfig != null) {
    return customConfig;
  }
  return difficultyConfigs[difficulty]!;
}

String difficultyKey(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return 'easy';
    case Difficulty.medium:
      return 'medium';
    case Difficulty.hard:
      return 'hard';
    case Difficulty.custom:
      return 'custom';
  }
}

Difficulty parseDifficulty(String raw) {
  switch (raw) {
    case 'easy':
      return Difficulty.easy;
    case 'hard':
      return Difficulty.hard;
    case 'custom':
      return Difficulty.custom;
    case 'medium':
    default:
      return Difficulty.medium;
  }
}

class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int createdAt;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'P';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'createdAt': createdAt};
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}

String gameStatusKey(GameStatus status) {
  switch (status) {
    case GameStatus.won:
      return 'won';
    case GameStatus.lost:
      return 'lost';
    case GameStatus.inProgress:
      return 'in_progress';
  }
}

GameStatus parseGameStatus(String raw) {
  switch (raw) {
    case 'won':
      return GameStatus.won;
    case 'lost':
      return GameStatus.lost;
    case 'in_progress':
    default:
      return GameStatus.inProgress;
  }
}

String guessOutcomeKey(GuessOutcome outcome) {
  switch (outcome) {
    case GuessOutcome.correct:
      return 'correct';
    case GuessOutcome.tooHigh:
      return 'too_high';
    case GuessOutcome.tooLow:
      return 'too_low';
  }
}

GuessOutcome parseGuessOutcome(String raw) {
  switch (raw) {
    case 'correct':
      return GuessOutcome.correct;
    case 'too_high':
      return GuessOutcome.tooHigh;
    case 'too_low':
    default:
      return GuessOutcome.tooLow;
  }
}

class GuessRecord {
  const GuessRecord({
    required this.value,
    required this.outcome,
    required this.distance,
    required this.timestamp,
  });

  final int value;
  final GuessOutcome outcome;
  final int distance;
  final int timestamp;

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'outcome': guessOutcomeKey(outcome),
      'distance': distance,
      'timestamp': timestamp,
    };
  }

  factory GuessRecord.fromJson(Map<String, dynamic> json) {
    return GuessRecord(
      value: json['value'] as int? ?? 0,
      outcome: parseGuessOutcome(json['outcome'] as String? ?? 'too_low'),
      distance: json['distance'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

class GameRecord {
  const GameRecord({
    required this.id,
    required this.difficulty,
    required this.target,
    required this.attempts,
    required this.maxAttempts,
    required this.status,
    required this.score,
    required this.guesses,
    required this.startedAt,
    required this.finishedAt,
    required this.hintsUsed,
    required this.playerId,
    required this.playerName,
    this.customConfig,
  });

  final String id;
  final Difficulty difficulty;
  final int target;
  final int attempts;
  final int maxAttempts;
  final GameStatus status;
  final int score;
  final List<GuessRecord> guesses;
  final int startedAt;
  final int finishedAt;
  final int hintsUsed;
  final String playerId;
  final String playerName;
  final DifficultyConfig? customConfig;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficulty': difficultyKey(difficulty),
      'target': target,
      'attempts': attempts,
      'maxAttempts': maxAttempts,
      'status': gameStatusKey(status),
      'score': score,
      'guesses': guesses.map((guess) => guess.toJson()).toList(),
      'startedAt': startedAt,
      'finishedAt': finishedAt,
      'hintsUsed': hintsUsed,
      'playerId': playerId,
      'playerName': playerName,
      if (customConfig case final config?) 'customConfig': config.toJson(),
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final guessesJson = json['guesses'] as List<dynamic>? ?? const [];
    return GameRecord(
      id: json['id'] as String? ?? '',
      difficulty: parseDifficulty(json['difficulty'] as String? ?? 'medium'),
      target: json['target'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      maxAttempts: json['maxAttempts'] as int? ?? 0,
      status: parseGameStatus(json['status'] as String? ?? 'lost'),
      score: json['score'] as int? ?? 0,
      guesses: guessesJson
          .whereType<Map<String, dynamic>>()
          .map(GuessRecord.fromJson)
          .toList(),
      startedAt: json['startedAt'] as int? ?? 0,
      finishedAt: json['finishedAt'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      playerId: json['playerId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? 'Player',
      customConfig: json['customConfig'] is Map<String, dynamic>
          ? DifficultyConfig.fromJson(
              json['customConfig'] as Map<String, dynamic>,
              Difficulty.custom,
            )
          : null,
    );
  }
}

class ActiveGame {
  const ActiveGame({
    required this.id,
    required this.difficulty,
    required this.target,
    required this.attempts,
    required this.guesses,
    required this.hintsUsed,
    required this.startedAt,
    this.customConfig,
  });

  final String id;
  final Difficulty difficulty;
  final int target;
  final int attempts;
  final List<GuessRecord> guesses;
  final int hintsUsed;
  final int startedAt;
  final DifficultyConfig? customConfig;

  ActiveGame copyWith({
    String? id,
    Difficulty? difficulty,
    int? target,
    int? attempts,
    List<GuessRecord>? guesses,
    int? hintsUsed,
    int? startedAt,
    DifficultyConfig? customConfig,
  }) {
    return ActiveGame(
      id: id ?? this.id,
      difficulty: difficulty ?? this.difficulty,
      target: target ?? this.target,
      attempts: attempts ?? this.attempts,
      guesses: guesses ?? this.guesses,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      startedAt: startedAt ?? this.startedAt,
      customConfig: customConfig ?? this.customConfig,
    );
  }
}

class StreakData {
  const StreakData({
    required this.current,
    required this.best,
    required this.lastWonAt,
  });

  final int current;
  final int best;
  final int? lastWonAt;

  static const StreakData defaults = StreakData(
    current: 0,
    best: 0,
    lastWonAt: null,
  );

  StreakData copyWith({
    int? current,
    int? best,
    int? lastWonAt,
    bool clearLastWonAt = false,
  }) {
    return StreakData(
      current: current ?? this.current,
      best: best ?? this.best,
      lastWonAt: clearLastWonAt ? null : lastWonAt ?? this.lastWonAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {'current': current, 'best': best, 'lastWonAt': lastWonAt};
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      current: json['current'] as int? ?? 0,
      best: json['best'] as int? ?? 0,
      lastWonAt: json['lastWonAt'] as int?,
    );
  }
}

class SettingsData {
  const SettingsData({
    required this.preferredDifficulty,
    required this.hapticsEnabled,
  });

  final Difficulty preferredDifficulty;
  final bool hapticsEnabled;

  static const SettingsData defaults = SettingsData(
    preferredDifficulty: Difficulty.medium,
    hapticsEnabled: true,
  );

  SettingsData copyWith({
    Difficulty? preferredDifficulty,
    bool? hapticsEnabled,
  }) {
    return SettingsData(
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredDifficulty': difficultyKey(preferredDifficulty),
      'hapticsEnabled': hapticsEnabled,
    };
  }

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      preferredDifficulty: parseDifficulty(
        json['preferredDifficulty'] as String? ?? 'medium',
      ),
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }
}

class SubmitGuessResult {
  const SubmitGuessResult({
    required this.record,
    required this.finished,
    this.finishedRecord,
  });

  final GuessRecord record;
  final bool finished;
  final GameRecord? finishedRecord;
}

int generateTarget(DifficultyConfig config, Random random) {
  return random.nextInt(config.max - config.min + 1) + config.min;
}

GuessOutcome evaluateGuess(int guess, int target) {
  if (guess == target) {
    return GuessOutcome.correct;
  }
  return guess > target ? GuessOutcome.tooHigh : GuessOutcome.tooLow;
}

String getProximity(int guess, int target, int range) {
  final distance = (guess - target).abs();
  final pct = distance / range;
  if (distance == 0) {
    return 'burning';
  }
  if (pct <= 0.05) {
    return 'burning';
  }
  if (pct <= 0.1) {
    return 'hot';
  }
  if (pct <= 0.2) {
    return 'warm';
  }
  if (pct <= 0.35) {
    return 'cool';
  }
  if (pct <= 0.55) {
    return 'cold';
  }
  return 'freezing';
}

int calculateScore(
  DifficultyConfig difficulty,
  int attempts,
  int hintsUsed,
  bool won,
) {
  if (!won) {
    return 0;
  }
  final attemptPenalty =
      (attempts - 1) *
      (difficulty.basePoints / difficulty.maxAttempts / 2).round();
  final hintPenalty = hintsUsed * 25;
  final score = difficulty.basePoints - attemptPenalty - hintPenalty;
  return max(score, 25);
}

String generateId(Random random) {
  final suffix = random.nextInt(0x7fffffff).toRadixString(36);
  return '${DateTime.now().millisecondsSinceEpoch}$suffix';
}

String formatRange(DifficultyConfig config) {
  return '${config.min} - ${config.max}';
}

String getHint(
  int target, {
  required int min,
  required int max,
  required Random random,
}) {
  final options = <String>[];
  options.add(target.isEven ? "It's an even number" : "It's an odd number");
  if (target % 5 == 0) {
    options.add("It's a multiple of 5");
  }
  if (target % 3 == 0) {
    options.add("It's a multiple of 3");
  }
  final half = ((min + max) / 2).floor();
  options.add(
    target > half
        ? "It's greater than $half"
        : "It's less than or equal to $half",
  );
  final lastDigit = target % 10;
  options.add('The last digit is $lastDigit');
  final digitSum = target
      .toString()
      .split('')
      .map(int.parse)
      .fold<int>(0, (sum, value) => sum + value);
  options.add('The sum of its digits is $digitSum');
  if (options.isEmpty) {
    return 'No hint available';
  }
  return options[random.nextInt(options.length)];
}
