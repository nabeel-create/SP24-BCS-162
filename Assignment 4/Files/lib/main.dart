import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/news_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, WeatherProvider>(
          create: (ctx) => WeatherProvider(),
          update: (ctx, settings, weather) => weather!..updateSettings(settings),
        ),
      ],
      child: const AuraWeatherApp(),
    ),
  );
}

class AuraWeatherApp extends StatelessWidget {
  const AuraWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1026),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7AB8FF),
          secondary: Color(0xFFFFB36B),
          surface: Color(0xFF0B1026),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  static const _screens = [
    HomeScreen(),
    MapScreen(),
    NewsScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _BottomBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.cloud_outlined, Icons.cloud, 'Weather'),
      (Icons.map_outlined, Icons.map, 'Map'),
      (Icons.newspaper_outlined, Icons.newspaper, 'News'),
      (Icons.bookmark_outline, Icons.bookmark, 'Saved'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB0B1026),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.10), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, iconActive, label) = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? iconActive : icon,
                        size: 22,
                        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
