import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(
        children: [
          const AnimatedBackground(weatherCode: 2, isDay: true),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text('Settings', style: TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),

                      // Location
                      _SectionHeader(title: 'LOCATION'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _ToggleRow(
                          icon: Icons.location_on,
                          iconBg: Colors.blue.withOpacity(0.18),
                          iconColor: const Color(0xFF7AB8FF),
                          title: 'Auto-location',
                          subtitle: 'Use GPS to detect your current position',
                          value: sp.autoLocation,
                          onToggle: (v) => sp.setAutoLocation(v),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display
                      _SectionHeader(title: 'DISPLAY'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            _SelectRow(
                              icon: Icons.thermostat,
                              iconBg: const Color(0xFFFF9A3C).withOpacity(0.18),
                              iconColor: const Color(0xFFFF9A3C),
                              title: 'Temperature',
                              child: _Segment(
                                options: [('°C', 'C'), ('°F', 'F')],
                                value: sp.tempUnit,
                                onSelect: (v) => sp.setTempUnit(v),
                              ),
                            ),
                            _Divider(),
                            _SelectRow(
                              icon: Icons.speed,
                              iconBg: const Color(0xFF80CBC4).withOpacity(0.18),
                              iconColor: const Color(0xFF80CBC4),
                              title: 'Wind speed',
                              child: _Segment(
                                options: [('km/h', 'kmh'), ('mph', 'mph')],
                                value: sp.windUnit,
                                onSelect: (v) => sp.setWindUnit(v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Auto refresh
                      _SectionHeader(title: 'AUTO REFRESH'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _SelectRow(
                          icon: Icons.refresh,
                          iconBg: const Color(0xFFA5D6A7).withOpacity(0.18),
                          iconColor: const Color(0xFFA5D6A7),
                          title: 'Refresh every',
                          child: _Segment(
                            options: [('Off', '0'), ('5m', '5'), ('15m', '15'), ('30m', '30')],
                            value: sp.refreshInterval.toString(),
                            onSelect: (v) => sp.setRefreshInterval(int.parse(v)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // About
                      _SectionHeader(title: 'ABOUT'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            _AboutRow(
                              icon: Icons.cloud, iconBg: const Color(0xFF7AB8FF).withOpacity(0.18),
                              iconColor: const Color(0xFF7AB8FF),
                              title: 'Aura Weather (Flutter)', subtitle: 'Version 1.0.0'),
                            _Divider(),
                            _AboutRow(
                              icon: Icons.public, iconBg: const Color(0xFFA5D6A7).withOpacity(0.18),
                              iconColor: const Color(0xFFA5D6A7),
                              title: 'Weather data', subtitle: 'Open-Meteo (open-meteo.com)'),
                            _Divider(),
                            _AboutRow(
                              icon: Icons.map_outlined, iconBg: const Color(0xFFFFD566).withOpacity(0.18),
                              iconColor: const Color(0xFFFFD566),
                              title: 'Location search', subtitle: 'OpenStreetMap Nominatim'),
                          ],
                        ),
                      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(title, style: TextStyle(
          color: Colors.white.withOpacity(0.45), fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final void Function(bool) onToggle;

  const _ToggleRow({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, this.subtitle, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w500)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 12, height: 1.3)),
            ],
          )),
          Switch(
            value: value,
            onChanged: onToggle,
            activeColor: const Color(0xFF4A90E2),
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SelectRow({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
          child,
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _AboutRow({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          )),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(color: Colors.white.withOpacity(0.08), height: 0.5, thickness: 0.5),
    );
  }
}

class _Segment extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final void Function(String) onSelect;

  const _Segment({required this.options, required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (label, val) = opt;
        final isActive = val == value;
        return GestureDetector(
          onTap: () => onSelect(val),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF7AB8FF).withOpacity(0.25)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF7AB8FF).withOpacity(0.5)
                    : Colors.white.withOpacity(0.10),
              ),
            ),
            child: Text(label, style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ),
        );
      }).toList(),
    );
  }
}
