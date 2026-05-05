import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

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
                  const Text('News', style: TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Weather headlines & alerts', style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 14)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GlassCard(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.newspaper_outlined, size: 56,
                                color: Colors.white.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('Weather News', style: TextStyle(
                                color: Colors.white.withOpacity(0.7), fontSize: 18,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Local weather news and alerts\ncoming soon',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.45),
                                    fontSize: 13, height: 1.5)),
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
