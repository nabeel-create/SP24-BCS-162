import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class WeatherService {
  static const String _baseUrl = '/api';
final String apiKey = '2bff7a29bf103cf0d38e5d2876c36170';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static Future<WeatherBundle> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather request failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return WeatherBundle.fromJson(data);
  }

  static Future<List<CitySearchResult>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$_baseUrl/weather/search?q=${Uri.encodeComponent(query)}');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((r) => CitySearchResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final res = await http.get(uri, headers: {'User-Agent': 'AuraWeather/1.0'});
      if (res.statusCode != 200) return 'Current Location';
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      final city = address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['county'];
      return city as String? ?? 'Current Location';
    } catch (_) {
      return 'Current Location';
    }
  }
}
