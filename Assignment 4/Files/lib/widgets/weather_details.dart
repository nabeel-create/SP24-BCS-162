import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import 'glass_card.dart';

class WeatherDetails extends StatelessWidget {
  final CurrentWeather current;
  final String windSymbol;

  const WeatherDetails({super.key, required this.current, required this.windSymbol});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(icon: Icons.air, label: 'Wind', value: '${current.windSpeed.round()} $windSymbol',
          color: const Color(0xFFA8E0FF)),
      _Item(icon: Icons.water_drop, label: 'Humidity', value: '${current.humidity.round()}%',
          color: const Color(0xFF9DD2FF)),
      _Item(icon: Icons.visibility, label: 'Visibility',
          value: '${(current.visibility).toStringAsFixed(0)} km', color: const Color(0xFFCCE8FF)),
      _Item(icon: Icons.compress, label: 'Pressure',
          value: '${current.pressure.round()} hPa', color: const Color(0xFFBFD0FF)),
      _Item(icon: Icons.cloud, label: 'Cloud Cover',
          value: '${current.cloudCover.round()}%', color: Colors.white70),
      _Item(icon: Icons.water, label: 'Precipitation',
          value: '${current.precipitation.toStringAsFixed(1)} mm', color: const Color(0xFF9DD2FF)),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.grid_view, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('WEATHER DETAILS',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.3,
              children: items.map((item) => _DetailTile(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Item({required this.icon, required this.label, required this.value, required this.color});
}

class _DetailTile extends StatelessWidget {
  final _Item item;
  const _DetailTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10,
                        fontWeight: FontWeight.w500)),
                Text(item.value,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
