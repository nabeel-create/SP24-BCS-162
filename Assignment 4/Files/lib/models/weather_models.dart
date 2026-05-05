class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double precipitation;
  final int weatherCode;
  final double cloudCover;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final bool isDay;
  final double uvIndex;
  final double visibility;
  final String sunrise;
  final String sunset;

  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.cloudCover,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.isDay,
    required this.uvIndex,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature'] as num).toDouble(),
      apparentTemperature: (json['apparentTemperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      precipitation: (json['precipitation'] as num? ?? 0).toDouble(),
      weatherCode: json['weatherCode'] as int,
      cloudCover: (json['cloudCover'] as num? ?? 0).toDouble(),
      pressure: (json['pressure'] as num? ?? 1013).toDouble(),
      windSpeed: (json['windSpeed'] as num? ?? 0).toDouble(),
      windDirection: (json['windDirection'] as num? ?? 0).toDouble(),
      isDay: json['isDay'] as bool? ?? true,
      uvIndex: (json['uvIndex'] as num? ?? 0).toDouble(),
      visibility: (json['visibility'] as num? ?? 10).toDouble(),
      sunrise: json['sunrise'] as String? ?? '',
      sunset: json['sunset'] as String? ?? '',
    );
  }
}

class HourlyEntry {
  final String time;
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final double precipitationProbability;
  final bool isDay;

  const HourlyEntry({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.isDay,
  });

  factory HourlyEntry.fromJson(Map<String, dynamic> json) {
    return HourlyEntry(
      time: json['time'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      apparentTemperature: (json['apparentTemperature'] as num? ?? json['temperature'] as num).toDouble(),
      weatherCode: json['weatherCode'] as int,
      precipitationProbability: (json['precipitationProbability'] as num? ?? 0).toDouble(),
      isDay: json['isDay'] as bool? ?? true,
    );
  }
}

class DailyEntry {
  final String date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final double precipitationProbability;
  final String sunrise;
  final String sunset;
  final double uvIndexMax;

  const DailyEntry({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationProbability,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
  });

  factory DailyEntry.fromJson(Map<String, dynamic> json) {
    return DailyEntry(
      date: json['date'] as String,
      weatherCode: json['weatherCode'] as int,
      tempMax: (json['tempMax'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      precipitationProbability: (json['precipitationProbability'] as num? ?? 0).toDouble(),
      sunrise: json['sunrise'] as String? ?? '',
      sunset: json['sunset'] as String? ?? '',
      uvIndexMax: (json['uvIndexMax'] as num? ?? 0).toDouble(),
    );
  }
}

class WeatherBundle {
  final CurrentWeather current;
  final List<HourlyEntry> hourly;
  final List<DailyEntry> daily;
  final String timezone;
  final double? aqi;

  const WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.timezone,
    this.aqi,
  });

  factory WeatherBundle.fromJson(Map<String, dynamic> json) {
    return WeatherBundle(
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      hourly: (json['hourly'] as List<dynamic>)
          .map((h) => HourlyEntry.fromJson(h as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List<dynamic>)
          .map((d) => DailyEntry.fromJson(d as Map<String, dynamic>))
          .toList(),
      timezone: json['timezone'] as String? ?? 'UTC',
      aqi: (json['aqi'] as num?)?.toDouble(),
    );
  }
}

class SavedLocation {
  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final bool isCurrent;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'region': region,
    'latitude': latitude,
    'longitude': longitude,
    'isCurrent': isCurrent,
  };

  SavedLocation copyWith({String? name, String? region, bool? isCurrent}) {
    return SavedLocation(
      id: id,
      name: name ?? this.name,
      region: region ?? this.region,
      latitude: latitude,
      longitude: longitude,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

class CitySearchResult {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;

  const CitySearchResult({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
  });

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String? ?? '',
      admin1: json['admin1'] as String?,
    );
  }
}
