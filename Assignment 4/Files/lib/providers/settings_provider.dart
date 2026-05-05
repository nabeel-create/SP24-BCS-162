import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _autoLocation = true;
  String _tempUnit = 'C';
  String _windUnit = 'kmh';
  int _refreshInterval = 0;

  bool get autoLocation => _autoLocation;
  String get tempUnit => _tempUnit;
  String get windUnit => _windUnit;
  int get refreshInterval => _refreshInterval;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoLocation = prefs.getBool('autoLocation') ?? true;
    _tempUnit = prefs.getString('tempUnit') ?? 'C';
    _windUnit = prefs.getString('windUnit') ?? 'kmh';
    _refreshInterval = prefs.getInt('refreshInterval') ?? 0;
    notifyListeners();
  }

  Future<void> setAutoLocation(bool v) async {
    _autoLocation = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoLocation', v);
    notifyListeners();
  }

  Future<void> setTempUnit(String v) async {
    _tempUnit = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempUnit', v);
    notifyListeners();
  }

  Future<void> setWindUnit(String v) async {
    _windUnit = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('windUnit', v);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int v) async {
    _refreshInterval = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshInterval', v);
    notifyListeners();
  }

  double convertTemp(double celsius) {
    if (_tempUnit == 'F') return celsius * 9 / 5 + 32;
    return celsius;
  }

  String get tempSymbol => _tempUnit == 'F' ? '°F' : '°C';

  double convertWind(double kmh) {
    if (_windUnit == 'mph') return kmh * 0.621371;
    return kmh;
  }

  String get windSymbol => _windUnit == 'mph' ? 'mph' : 'km/h';
}
