import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

enum AppThemeMode { light, dark, system }

AppThemeMode _parseMode(String? s) {
  switch (s) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    case 'system':
    default:
      return AppThemeMode.system;
  }
}

String _modeToStr(AppThemeMode m) {
  switch (m) {
    case AppThemeMode.light:
      return 'light';
    case AppThemeMode.dark:
      return 'dark';
    case AppThemeMode.system:
      return 'system';
  }
}

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeMode _mode = AppThemeMode.system;
  Brightness _platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  AppThemeMode get themeMode => _mode;

  bool get isDark {
    if (_mode == AppThemeMode.system) {
      return _platformBrightness == Brightness.dark;
    }
    return _mode == AppThemeMode.dark;
  }

  AppPalette get colors => isDark ? AppPalette.dark : AppPalette.light;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = _parseMode(prefs.getString('themeMode'));
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _modeToStr(m));
  }

  @override
  void didChangePlatformBrightness() {
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_mode == AppThemeMode.system) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
