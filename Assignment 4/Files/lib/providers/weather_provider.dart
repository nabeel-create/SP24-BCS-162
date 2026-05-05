import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather_models.dart';
import '../services/weather_service.dart';
import 'settings_provider.dart';

class WeatherProvider extends ChangeNotifier {
  bool _loading = true;
  String? _error;
  bool _permissionDenied = false;
  WeatherBundle? _weather;
  SavedLocation? _selected;
  String _placePrimary = '';
  String _placeSecondary = '';
  List<SavedLocation> _saved = [];

  bool get loading => _loading;
  String? get error => _error;
  bool get permissionDenied => _permissionDenied;
  WeatherBundle? get weather => _weather;
  SavedLocation? get selected => _selected;
  String get placePrimary => _placePrimary;
  String get placeSecondary => _placeSecondary;
  List<SavedLocation> get saved => _saved;

  static const String _savedKey = '@aura/saved-locations';
  static const String _selectedKey = '@aura/selected-location';

  WeatherProvider() {
    _init();
  }

  void updateSettings(SettingsProvider settings) {
    // Settings changes can trigger refreshes if needed
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRaw = prefs.getString(_savedKey);
      final selectedRaw = prefs.getString(_selectedKey);

      if (savedRaw != null) {
        try {
          final list = jsonDecode(savedRaw) as List<dynamic>;
          _saved = list.map((e) => SavedLocation.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      SavedLocation? initial;
      if (selectedRaw != null) {
        try {
          initial = SavedLocation.fromJson(jsonDecode(selectedRaw) as Map<String, dynamic>);
        } catch (_) {}
      }

      if (initial != null && !initial.isCurrent) {
        await _loadWeatherFor(initial);
        return;
      }

      // Try GPS
      final gpsLoc = await _getCurrentLocationSilent();
      if (gpsLoc != null) {
        await _loadWeatherFor(gpsLoc);
        return;
      }

      if (initial != null) {
        await _loadWeatherFor(initial);
        return;
      }

      // Fallback to London
      await _loadWeatherFor(const SavedLocation(
        id: 'fallback-london',
        name: 'London',
        region: 'United Kingdom',
        latitude: 51.5074,
        longitude: -0.1278,
      ));
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<SavedLocation?> _getCurrentLocationSilent() async {
    try {
      if (kIsWeb) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _permissionDenied = true;
          return null;
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        return SavedLocation(
          id: 'current',
          name: 'Current Location',
          region: '',
          latitude: pos.latitude,
          longitude: pos.longitude,
          isCurrent: true,
        );
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          _permissionDenied = true;
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _permissionDenied = true;
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _permissionDenied = false;
      return SavedLocation(
        id: 'current',
        name: 'Current Location',
        region: '',
        latitude: pos.latitude,
        longitude: pos.longitude,
        isCurrent: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadWeatherFor(SavedLocation loc) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final w = await WeatherService.fetchWeather(loc.latitude, loc.longitude);
      _weather = w;

      if (loc.isCurrent) {
        final cityName = await WeatherService.reverseGeocode(loc.latitude, loc.longitude);
        _placePrimary = cityName;
        _placeSecondary = '';
        _selected = loc.copyWith(name: cityName);
      } else {
        _placePrimary = loc.name;
        _placeSecondary = loc.region;
        _selected = loc;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedKey, jsonEncode(_selected!.toJson()));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    final loc = await _getCurrentLocationSilent();
    if (loc != null) await _loadWeatherFor(loc);
  }

  Future<void> selectLocation(SavedLocation loc) async {
    await _loadWeatherFor(loc);
  }

  Future<void> refresh() async {
    if (_selected != null) await _loadWeatherFor(_selected!);
  }

  Future<void> addSaved(SavedLocation loc) async {
    final exists = _saved.any(
      (s) => (s.latitude - loc.latitude).abs() < 0.01 && (s.longitude - loc.longitude).abs() < 0.01,
    );
    if (!exists) {
      _saved = [..._saved, loc];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKey, jsonEncode(_saved.map((s) => s.toJson()).toList()));
      notifyListeners();
    }
  }

  Future<void> removeSaved(String id) async {
    _saved = _saved.where((s) => s.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedKey, jsonEncode(_saved.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  bool get isSaved {
    if (_selected == null) return false;
    return _saved.any(
      (s) =>
          (s.latitude - _selected!.latitude).abs() < 0.01 &&
          (s.longitude - _selected!.longitude).abs() < 0.01,
    );
  }
}
