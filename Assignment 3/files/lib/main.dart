import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/bmi_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_tabs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HealthScaleApp());
}

class HealthScaleApp extends StatelessWidget {
  const HealthScaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BMIProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          final colors = theme.colors;
          final brightness = theme.isDark ? Brightness.dark : Brightness.light;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  theme.isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness:
                  theme.isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: colors.background,
              systemNavigationBarIconBrightness:
                  theme.isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'Health-Scale',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: brightness,
              scaffoldBackgroundColor: colors.background,
              colorScheme: ColorScheme(
                brightness: brightness,
                primary: colors.primary,
                onPrimary: colors.primaryForeground,
                secondary: colors.accent,
                onSecondary: colors.accentForeground,
                surface: colors.card,
                onSurface: colors.foreground,
                error: colors.destructive,
                onError: colors.destructiveForeground,
              ),
              textTheme: GoogleFonts.interTextTheme(
                ThemeData(brightness: brightness).textTheme,
              ).apply(
                bodyColor: colors.foreground,
                displayColor: colors.foreground,
              ),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            home: const MainTabs(),
          );
        },
      ),
    );
  }
}
