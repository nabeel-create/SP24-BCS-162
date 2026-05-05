import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/current_hero.dart';
import '../widgets/glass_card.dart';
import '../widgets/hourly_forecast.dart';
import '../widgets/week_strip.dart';
import '../widgets/daily_forecast.dart';
import '../widgets/weather_details.dart';
import '../widgets/temp_chart.dart';
import '../widgets/rain_chart.dart';
import '../widgets/sun_arc.dart';
import '../widgets/wind_compass.dart';
import '../widgets/uv_card.dart';
import '../widgets/aqi_card.dart';
import '../widgets/smart_suggestions.dart';
import '../widgets/weather_alert_banner.dart';
import '../widgets/search_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final sp = context.watch<SettingsProvider>();

    if (wp.loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1026),
        body: Stack(children: [
          const AnimatedBackground(weatherCode: 0, isDay: true),
          const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF7AB8FF), strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading weather...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )),
        ]),
      );
    }

    if (wp.error != null && wp.weather == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1026),
        body: Stack(children: [
          const AnimatedBackground(weatherCode: 0, isDay: true),
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
                const SizedBox(height: 16),
                const Text('Unable to load weather', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(wp.error!.replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => wp.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AB8FF),
                    foregroundColor: const Color(0xFF0B1026),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          )),
        ]),
      );
    }

    final w = wp.weather!;
    final code = w.current.weatherCode;
    final isDay = w.current.isDay;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(
        children: [
          AnimatedBackground(weatherCode: code, isDay: isDay),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => wp.refresh(),
              color: const Color(0xFF7AB8FF),
              backgroundColor: const Color(0xFF1B2A5E),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: CurrentHero(
                          current: w.current,
                          today: w.daily.isNotEmpty ? w.daily[0] : null,
                          placePrimary: wp.placePrimary,
                          placeSecondary: wp.placeSecondary,
                          isSaved: wp.isSaved,
                          onSearchPress: () {
                            showSearchSheet(context,
                              onSelect: (r) {
                                final loc = SavedLocation(
                                  id: '${r.latitude.toStringAsFixed(3)}-${r.longitude.toStringAsFixed(3)}',
                                  name: r.name,
                                  region: [r.admin1, r.country]
                                      .where((s) => s != null && s.isNotEmpty)
                                      .join(', '),
                                  latitude: r.latitude,
                                  longitude: r.longitude,
                                );
                                wp.selectLocation(loc);
                              },
                              onUseCurrent: () => wp.useCurrentLocation(),
                            );
                          },
                          onSavePress: () {
                            if (wp.isSaved) {
                              if (wp.selected != null) wp.removeSaved(wp.selected!.id);
                            } else {
                              if (wp.selected != null) wp.addSaved(wp.selected!);
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Alerts
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WeatherAlertBanner(current: w.current),
                      ),

                      // Hourly
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HourlyForecast(hourly: w.hourly),
                      ),
                      const SizedBox(height: 12),

                      // Week strip
                      if (w.daily.isNotEmpty) ...[
                        WeekStrip(daily: w.daily),
                        const SizedBox(height: 12),
                      ],

                      // Temp chart
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TempChart(hourly: w.hourly),
                      ),
                      const SizedBox(height: 12),

                      // Rain chart
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RainChart(hourly: w.hourly),
                      ),
                      const SizedBox(height: 12),

                      // Smart suggestions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SmartSuggestions(
                          current: w.current,
                          daily: w.daily,
                          aqi: w.aqi,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Weather details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WeatherDetails(
                          current: w.current,
                          windSymbol: sp.windSymbol,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sun arc
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SunArc(current: w.current),
                      ),
                      const SizedBox(height: 12),

                      // Wind compass
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WindCompass(current: w.current, windSymbol: sp.windSymbol),
                      ),
                      const SizedBox(height: 12),

                      // UV card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: UvCard(current: w.current),
                      ),
                      const SizedBox(height: 12),

                      // AQI card
                      if (w.aqi != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AqiCard(aqi: w.aqi),
                        ),
                      if (w.aqi != null) const SizedBox(height: 12),

                      // 7-day forecast
                      if (w.daily.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DailyForecast(daily: w.daily),
                        ),

                      const SizedBox(height: 100),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
