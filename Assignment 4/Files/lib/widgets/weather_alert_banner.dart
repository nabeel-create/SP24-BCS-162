import 'package:flutter/material.dart';
import '../models/weather_models.dart';

class _Alert {
  final String id;
  final String level;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color bg;
  const _Alert({required this.id, required this.level, required this.icon,
      required this.title, required this.body, required this.color, required this.bg});
}

List<_Alert> _detectAlerts(CurrentWeather c) {
  final alerts = <_Alert>[];
  final code = c.weatherCode;

  if (code == 99) {
    alerts.add(_Alert(id: 'ts-hail', level: 'SEVERE', icon: Icons.warning_amber,
        title: 'Thunderstorm with Hail',
        body: 'Large hail possible. Stay indoors and away from windows.',
        color: const Color(0xFFFF4C4C), bg: const Color(0xFF2A1010)));
  } else if (code >= 95 && code <= 99) {
    alerts.add(_Alert(id: 'ts', level: 'SEVERE', icon: Icons.bolt,
        title: 'Thunderstorm Active',
        body: 'Lightning and heavy rain. Avoid open areas and tall trees.',
        color: const Color(0xFFFF6B35), bg: const Color(0xFF2A1A0D)));
  }
  if (code == 75 || code == 77 || code == 85 || code == 86) {
    alerts.add(_Alert(id: 'blizzard', level: 'SEVERE', icon: Icons.ac_unit,
        title: 'Heavy Snow / Blizzard',
        body: 'Severe snowfall expected. Travel may be dangerous.',
        color: const Color(0xFF7EB8FF), bg: const Color(0xFF0F1A2A)));
  } else if (code == 73 || code == 71) {
    alerts.add(_Alert(id: 'snow-mod', level: 'WARNING', icon: Icons.ac_unit,
        title: 'Moderate Snowfall',
        body: 'Accumulating snow. Drive carefully.',
        color: const Color(0xFF9DD2FF), bg: const Color(0xFF101C2A)));
  }
  if (code == 67 || code == 57) {
    alerts.add(_Alert(id: 'ice', level: 'SEVERE', icon: Icons.warning_amber,
        title: 'Freezing Rain',
        body: 'Ice forming on roads. Extremely slippery conditions.',
        color: const Color(0xFFB060FF), bg: const Color(0xFF1A1030)));
  }
  if (code == 65 || code == 82) {
    alerts.add(_Alert(id: 'heavy-rain', level: 'WARNING', icon: Icons.water_drop,
        title: 'Heavy Rain',
        body: 'Intense rainfall. Possible localized flooding.',
        color: const Color(0xFF4FC3F7), bg: const Color(0xFF0D1C26)));
  }
  if (c.windSpeed >= 88) {
    alerts.add(_Alert(id: 'gale', level: 'SEVERE', icon: Icons.warning_amber,
        title: 'Gale-Force Winds',
        body: '${c.windSpeed.round()} km/h gusts. Risk of structural damage.',
        color: const Color(0xFFFF8C42), bg: const Color(0xFF2A1A0A)));
  } else if (c.windSpeed >= 62) {
    alerts.add(_Alert(id: 'strong-wind', level: 'WARNING', icon: Icons.flag,
        title: 'Strong Wind Warning',
        body: '${c.windSpeed.round()} km/h winds. Secure loose outdoor items.',
        color: const Color(0xFFFFB347), bg: const Color(0xFF261D0D)));
  }
  if (c.uvIndex >= 11) {
    alerts.add(_Alert(id: 'ext-uv', level: 'SEVERE', icon: Icons.wb_sunny,
        title: 'Extreme UV Index',
        body: 'UV ${c.uvIndex.round()}. Avoid outdoor exposure. SPF 50+ required.',
        color: const Color(0xFFFF6B6B), bg: const Color(0xFF2A1010)));
  } else if (c.uvIndex >= 8) {
    alerts.add(_Alert(id: 'hi-uv', level: 'WARNING', icon: Icons.wb_sunny_outlined,
        title: 'Very High UV',
        body: 'UV ${c.uvIndex.round()}. Apply SPF 30+ and seek shade.',
        color: const Color(0xFFFFD662), bg: const Color(0xFF262010)));
  }
  return alerts;
}

class WeatherAlertBanner extends StatefulWidget {
  final CurrentWeather current;
  const WeatherAlertBanner({super.key, required this.current});

  @override
  State<WeatherAlertBanner> createState() => _WeatherAlertBannerState();
}

class _WeatherAlertBannerState extends State<WeatherAlertBanner> {
  final Set<String> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    final alerts = _detectAlerts(widget.current)
        .where((a) => !_dismissed.contains(a.id))
        .toList();
    if (alerts.isEmpty) return const SizedBox();

    return Column(
      children: alerts.map((a) => _AlertRow(
        alert: a,
        onDismiss: () => setState(() => _dismissed.add(a.id)),
      )).toList(),
    );
  }
}

class _AlertRow extends StatefulWidget {
  final _Alert alert;
  final VoidCallback onDismiss;
  const _AlertRow({required this.alert, required this.onDismiss});

  @override
  State<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends State<_AlertRow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _scale = Tween(begin: 1.0, end: 2.8).animate(_pulseCtrl);
    _opacity = Tween(begin: 0.8, end: 0.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: a.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        children: [
          Container(width: 3, height: double.infinity,
              color: a.color, margin: EdgeInsets.zero),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: Stack(alignment: Alignment.center, children: [
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: _scale.value,
                              child: Opacity(opacity: _opacity.value,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: a.color, width: 1)),
                                  )),
                            ),
                          ),
                          Container(width: 7, height: 7,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: a.color)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      Text(a.level, style: TextStyle(color: a.color, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(width: 4),
                      Icon(a.icon, size: 14, color: a.color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(a.body, style: TextStyle(color: Colors.white.withOpacity(0.7),
                      fontSize: 12, height: 1.35)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onDismiss,
            icon: Icon(Icons.close, size: 16, color: Colors.white.withOpacity(0.5)),
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }
}
