import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final code = wp.weather?.current.weatherCode ?? 0;
    final isDay = wp.weather?.current.isDay ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(
        children: [
          AnimatedBackground(weatherCode: code, isDay: isDay),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Map', style: TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GlassCard(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 56, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('Weather Map', style: TextStyle(
                                color: Colors.white.withOpacity(0.7), fontSize: 18,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Interactive radar and satellite maps\ncoming soon',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.45),
                                    fontSize: 13, height: 1.5)),
                            const SizedBox(height: 20),
                            if (wp.selected != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7AB8FF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: const Color(0xFF7AB8FF).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Color(0xFF7AB8FF)),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${wp.selected!.latitude.toStringAsFixed(2)}°N '
                                          '${wp.selected!.longitude.toStringAsFixed(2)}°E',
                                      style: const TextStyle(color: Color(0xFF7AB8FF),
                                          fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
