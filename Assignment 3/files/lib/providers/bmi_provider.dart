import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bmi_record.dart';
import '../models/user_profile.dart';
import '../utils/bmi_utils.dart';

enum UnitSystem { metric, imperial }

UnitSystem _parseUnit(String? s) {
  if (s == 'imperial') return UnitSystem.imperial;
  return UnitSystem.metric;
}

String _unitToStr(UnitSystem u) =>
    u == UnitSystem.imperial ? 'imperial' : 'metric';

class BMIProvider extends ChangeNotifier {
  static const _kHeightCm = 'heightCm';
  static const _kWeightKg = 'weightKg';
  static const _kAge = 'age';
  static const _kGender = 'gender';
  static const _kUnitSystem = 'unitSystem';
  static const _kBmiHistory = 'bmiHistory';
  static const _kProfile = 'userProfile';

  static const int _defHeightCm = 170;
  static const double _defWeightKg = 70;
  static const int _defAge = 25;

  int _heightCm = _defHeightCm;
  double _weightKg = _defWeightKg;
  int _age = _defAge;
  String _gender = 'male';
  UnitSystem _unitSystem = UnitSystem.metric;
  List<BMIRecord> _history = [];
  UserProfile _profile = UserProfile.defaults;
  bool _hydrated = false;

  BMIProvider() {
    _load();
  }

  // getters
  int get heightCm => _heightCm;
  double get weightKg => _weightKg;
  int get age => _age;
  String get gender => _gender;
  UnitSystem get unitSystem => _unitSystem;
  List<BMIRecord> get history => List.unmodifiable(_history);
  UserProfile get profile => _profile;
  bool get hydrated => _hydrated;
  double get bmi => calculateBMI(_weightKg, _heightCm);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final h = prefs.getString(_kHeightCm);
      final w = prefs.getString(_kWeightKg);
      final a = prefs.getString(_kAge);
      final g = prefs.getString(_kGender);
      final u = prefs.getString(_kUnitSystem);
      final hist = prefs.getString(_kBmiHistory);
      final prof = prefs.getString(_kProfile);

      if (h != null) _heightCm = int.tryParse(h) ?? _defHeightCm;
      if (w != null) _weightKg = double.tryParse(w) ?? _defWeightKg;
      if (a != null) _age = int.tryParse(a) ?? _defAge;
      if (g == 'male' || g == 'female') _gender = g!;
      if (u != null) _unitSystem = _parseUnit(u);

      if (hist != null) {
        final list = json.decode(hist) as List<dynamic>;
        _history = list
            .map((e) => BMIRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (prof != null) {
        _profile =
            UserProfile.fromJson(json.decode(prof) as Map<String, dynamic>);
      }
    } catch (_) {}

    _hydrated = true;
    notifyListeners();
  }

  // setters
  Future<void> setHeightCm(num v) async {
    final clamped = v.round().clamp(100, 250);
    _heightCm = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHeightCm, '$clamped');
  }

  Future<void> setWeightKg(num v) async {
    final clamped = ((v * 10).round() / 10).clamp(20.0, 300.0).toDouble();
    _weightKg = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeightKg, '$clamped');
  }

  Future<void> setAge(num v) async {
    final clamped = v.round().clamp(1, 120);
    _age = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAge, '$clamped');
  }

  Future<void> setGender(String g) async {
    _gender = g;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGender, g);
  }

  Future<void> setUnitSystem(UnitSystem u) async {
    _unitSystem = u;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnitSystem, _unitToStr(u));
  }

  Future<void> resetInputs() async {
    _heightCm = _defHeightCm;
    _weightKg = _defWeightKg;
    _age = _defAge;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kHeightCm, '$_defHeightCm'),
      prefs.setString(_kWeightKg, '$_defWeightKg'),
      prefs.setString(_kAge, '$_defAge'),
    ]);
  }

  Future<void> saveBMIRecord() async {
    final b = bmi;
    if (b <= 0) return;

    final id =
        '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999999).toRadixString(36)}';
    final rec = BMIRecord(
      id: id,
      date: DateTime.now().toUtc().toIso8601String(),
      bmi: b,
      category: getBMICategory(b),
      weight: _weightKg,
      height: _heightCm,
      weightUnit: 'kg',
      heightUnit: 'cm',
    );

    _history = [rec, ..._history].take(50).toList();
    notifyListeners();
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    _history = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBmiHistory);
  }

  Future<void> deleteHistoryRecord(String id) async {
    final next = _history.where((record) => record.id != id).toList();
    if (next.length == _history.length) return;
    _history = next;
    notifyListeners();
    await _persistHistory();
  }

  Future<void> updateProfile({String? name, int? age, String? gender}) async {
    _profile = _profile.copyWith(name: name, age: age, gender: gender);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfile, json.encode(_profile.toJson()));
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBmiHistory,
      json.encode(_history.map((r) => r.toJson()).toList()),
    );
  }
}
