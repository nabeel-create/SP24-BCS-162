import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/weather_codes.dart';
import 'glass_card.dart';

class CurrentHero extends StatelessWidget {
  final CurrentWeather current;
  final DailyEntry? today;
  final String placePrimary;
  final String placeSecondary;
  final VoidCallback onSearchPress;
  final VoidCallback onSavePress;
  final bool isSaved;
  final HourlyEntry? previewHour;

  const CurrentHero({
    super.key,
    required this.current,
    this.today,
    required this.placePrimary,
    required this.placeSecondary,
    required this.onSearchPress,
    required this.onSavePress,
    required this.isSaved,
    this.previewHour,
  });

  @override
  Widget build(BuildContext context) {
    final displayCode = previewHour?.weatherCode ?? current.weatherCode;
    final displayIsDay = previewHour?.isDay ?? current.isDay;
    final displayTemp = previewHour?.temperature ?? current.temperature;
    final iconColor = WeatherCodes.iconColorForCondition(displayCode, displayIsDay);
    final icon = WeatherCodes.iconForCondition(displayCode, displayIsDay);

    return Column(
      children: [
        // Top bar
        Row(
          children: [
            _IconButton(icon: Icons.search, onTap: onSearchPress),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          placePrimary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (placeSecondary.isNotEmpty)
                    Text(
                      placeSecondary,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _IconButton(
              icon: isSaved ? Icons.favorite : Icons.favorite_border,
              onTap: onSavePress,
              color: isSaved ? const Color(0xFFFF6B8A) : Colors.white,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Hero content
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (ctx, v, child) {
            return Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, (1 - v) * 20),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              Icon(icon, size: 88, color: iconColor),
              const SizedBox(height: 6),
              Text(
                '${displayTemp.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 96,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -4,
                  height: 1.0,
                ),
              ),
              Text(
                WeatherCodes.describeWeather(displayCode),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (today != null) ...[
                const SizedBox(height: 6),
                Text(
                  'H: ${today!.tempMax.round()}°  ·  L: ${today!.tempMin.round()}°',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _IconButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
        ),
        child: Icon(icon, size: 20, color: color ?? Colors.white),
      ),
    );
  }
}
