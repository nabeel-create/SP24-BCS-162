// main.dart
import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // ignore: unnecessary_const
      home: const SplashScreen(),
    );
  }
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp>
    with SingleTickerProviderStateMixin {
  int counter = 0;
  bool isDark = true;

  final TextEditingController _valueController = TextEditingController(
    text: "1",
  );

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  int get customValue {
    int value = int.tryParse(_valueController.text) ?? 1;
    return value > 0 ? value : 1;
  }

  Future<void> _animate() async {
    await _controller.forward();
    await _controller.reverse();
  }

  void increment() {
    setState(() {
      counter += customValue;
    });
    _animate();
  }

  void decrement() {
    if (counter - customValue >= 0) {
      setState(() {
        counter -= customValue;
      });
      _animate();
    }
  }

  void reset() {
    setState(() {
      counter = 0;
    });
    _animate();
  }

  void toggleBackground() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFD4AF37);

    final bgGradient = isDark
        ? [const Color(0xFF000000), const Color(0xFF111111)]
        : [const Color(0xFFFDF6E3), const Color(0xFFFFF8DC)];

    final cardColor = isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = isDark ? gold : Colors.black87;
    final fabBg = isDark ? gold : Colors.black87;
    final fabIcon = isDark ? Colors.black : gold;
    final toggleColor = isDark ? Colors.amber : Colors.deepPurple;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// Toggle Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: toggleBackground,
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: toggleColor,
                  ),
                ),
              ),

              /// MAIN CONTENT
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      /// Animated Counter Box
                      ScaleTransition(
                        scale: _animation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 70,
                            vertical: 50,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: gold, width: 2),
                          ),
                          child: Text(
                            "$counter",
                            style: TextStyle(
                              fontSize: 65,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      /// Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: "dec",
                            onPressed: decrement,
                            backgroundColor: fabBg,
                            foregroundColor: fabIcon,
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 30),
                          FloatingActionButton(
                            heroTag: "reset",
                            onPressed: reset,
                            backgroundColor: fabBg,
                            foregroundColor: fabIcon,
                            child: const Icon(Icons.refresh),
                          ),
                          const SizedBox(width: 30),
                          FloatingActionButton(
                            heroTag: "inc",
                            onPressed: increment,
                            backgroundColor: fabBg,
                            foregroundColor: fabIcon,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      /// Custom Value Input
                      Text(
                        "Enter custom value:",
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: gold, width: 1.5),
                        ),
                        child: TextField(
                          controller: _valueController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "1",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// FOOTER
              Column(
                children: [
                  Divider(
                    thickness: 1,
                    color: textColor.withOpacity(0.3),
                    indent: 50,
                    endIndent: 50,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Created by",
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "nabeel_create",
                    style: TextStyle(
                      color: gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
