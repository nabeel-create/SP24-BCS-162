import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'game_models.dart';

const String _historyFileName = 'history_v1.json';
const String _streakFileName = 'streak_v1.json';
const String _settingsFileName = 'settings_v1.json';
const String _playersFileName = 'players_v1.json';
const String _activePlayerFileName = 'active_player_v1.json';

Future<Directory> _storageDirectory() async {
  try {
    final basePath = await getDatabasesPath();
    final dir = Directory(p.join(basePath, 'numerix_store'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  } catch (_) {
    final dir = Directory(p.join(Directory.systemTemp.path, 'numerix_store'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

Future<File> _storageFile(String name) async {
  final dir = await _storageDirectory();
  return File(p.join(dir.path, name));
}

Future<dynamic> _readJsonFile(String name) async {
  try {
    final file = await _storageFile(name);
    if (!await file.exists()) {
      return null;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

Future<void> _writeJsonFile(String name, Object data) async {
  final file = await _storageFile(name);
  await file.writeAsString(jsonEncode(data), flush: true);
}

Future<List<GameRecord>> loadHistory() async {
  final json = await _readJsonFile(_historyFileName);
  if (json is! List) {
    return <GameRecord>[];
  }
  return json
      .whereType<Map<String, dynamic>>()
      .map(GameRecord.fromJson)
      .toList();
}

Future<void> saveHistory(List<GameRecord> records) async {
  await _writeJsonFile(
    _historyFileName,
    records.map((record) => record.toJson()).toList(),
  );
}

Future<List<GameRecord>> appendGame(GameRecord record) async {
  final existing = await loadHistory();
  final next = <GameRecord>[record, ...existing].take(200).toList();
  await saveHistory(next);
  return next;
}

Future<List<GameRecord>> deleteGame(String id) async {
  final existing = await loadHistory();
  final next = existing.where((game) => game.id != id).toList();
  await saveHistory(next);
  return next;
}

Future<void> clearHistory() async {
  await saveHistory(const <GameRecord>[]);
}

Future<List<PlayerProfile>> loadPlayers() async {
  final json = await _readJsonFile(_playersFileName);
  if (json is! List) {
    return <PlayerProfile>[];
  }
  return json
      .whereType<Map<String, dynamic>>()
      .map(PlayerProfile.fromJson)
      .where((player) => player.id.isNotEmpty)
      .toList();
}

Future<void> savePlayers(List<PlayerProfile> players) async {
  await _writeJsonFile(
    _playersFileName,
    players.map((player) => player.toJson()).toList(),
  );
}

Future<String?> loadActivePlayerId() async {
  final json = await _readJsonFile(_activePlayerFileName);
  if (json is Map<String, dynamic>) {
    return json['id'] as String?;
  }
  return null;
}

Future<void> saveActivePlayerId(String? id) async {
  await _writeJsonFile(_activePlayerFileName, {'id': id});
}

Future<StreakData> loadStreak() async {
  final json = await _readJsonFile(_streakFileName);
  if (json is! Map<String, dynamic>) {
    return StreakData.defaults;
  }
  return StreakData.fromJson(json);
}

Future<void> saveStreak(StreakData data) async {
  await _writeJsonFile(_streakFileName, data.toJson());
}

Future<SettingsData> loadSettings() async {
  final json = await _readJsonFile(_settingsFileName);
  if (json is! Map<String, dynamic>) {
    return SettingsData.defaults;
  }
  return SettingsData.fromJson(json);
}

Future<void> saveSettings(SettingsData data) async {
  await _writeJsonFile(_settingsFileName, data.toJson());
}
