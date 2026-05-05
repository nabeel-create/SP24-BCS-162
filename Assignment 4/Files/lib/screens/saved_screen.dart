import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/search_sheet.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      Row(
                        children: [
                          const Text('Locations', style: TextStyle(
                              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              showSearchSheet(context,
                                onSelect: (r) {
                                  final loc = SavedLocation(
                                    id: '${r.latitude.toStringAsFixed(3)}-${r.longitude.toStringAsFixed(3)}',
                                    name: r.name,
                                    region: [r.admin1, r.country]
                                        .where((s) => s != null && s.isNotEmpty).join(', '),
                                    latitude: r.latitude,
                                    longitude: r.longitude,
                                  );
                                  wp.addSaved(loc);
                                  wp.selectLocation(loc);
                                },
                                onUseCurrent: () => wp.useCurrentLocation(),
                              );
                            },
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.10),
                                border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Current location card
                      GestureDetector(
                        onTap: () => wp.useCurrentLocation(),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7AB8FF).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.my_location, color: Color(0xFF7AB8FF), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current location', style: TextStyle(
                                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text('Detect your precise area', style: TextStyle(
                                      color: Colors.white.withOpacity(0.55), fontSize: 12)),
                                ],
                              )),
                              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Saved locations or empty state
                      if (wp.saved.isEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(Icons.bookmark_border, size: 36, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(height: 10),
                              const Text('No saved locations', style: TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Tap + to add a city for quick access.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showSearchSheet(context,
                                    onSelect: (r) {
                                      final loc = SavedLocation(
                                        id: '${r.latitude.toStringAsFixed(3)}-${r.longitude.toStringAsFixed(3)}',
                                        name: r.name,
                                        region: [r.admin1, r.country]
                                            .where((s) => s != null && s.isNotEmpty).join(', '),
                                        latitude: r.latitude,
                                        longitude: r.longitude,
                                      );
                                      wp.addSaved(loc);
                                    },
                                    onUseCurrent: () => wp.useCurrentLocation(),
                                  );
                                },
                                icon: const Icon(Icons.search, size: 14),
                                label: const Text('Add location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0B1026),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        ...wp.saved.map((loc) => _SavedLocationCard(
                          loc: loc,
                          isActive: wp.selected != null &&
                              (wp.selected!.latitude - loc.latitude).abs() < 0.01,
                          onTap: () => wp.selectLocation(loc),
                          onRemove: () => wp.removeSaved(loc.id),
                        )).toList(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLocationCard extends StatelessWidget {
  final SavedLocation loc;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedLocationCard({
    required this.loc,
    required this.isActive,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          color: isActive ? const Color(0xFF1A2B4E).withOpacity(0.7) : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7AB8FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_city,
                    color: isActive ? const Color(0xFF7AB8FF) : Colors.white.withOpacity(0.6),
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.name, style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  if (loc.region.isNotEmpty)
                    Text(loc.region, style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 12)),
                ],
              )),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AB8FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('Active', style: TextStyle(
                      color: Color(0xFF7AB8FF), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
