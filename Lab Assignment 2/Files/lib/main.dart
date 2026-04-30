import 'package:flutter/material.dart';

import 'src/game_controller.dart';
import 'src/screens/home_screen.dart';
import 'src/theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GameController();
  await controller.initialize();
  runApp(GuessGameApp(controller: controller));
}

class GuessGameApp extends StatelessWidget {
  const GuessGameApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numerix',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: HomeScreen(controller: controller),
    );
  }
}
