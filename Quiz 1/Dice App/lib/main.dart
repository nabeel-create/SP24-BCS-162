// main.dart
// ============================================================
//  main.dart — Dice Roller Plus
//  Student  : Nabeel
//  Quiz 1   : Simple Dice App — Full Flutter Translation
//
//  This is an exact Flutter replica of the Expo/React Native
//  Dice-Roller-Plus app. Every feature is faithfully reproduced:
//
//  • Dice images loaded from assets/images/1.png – 6.png
//  • Per-face accent colors (pink, blue, purple, green, orange, cyan)
//  • Animated dice: rotation + scale-bounce + opacity flash
//  • Roll cycling: 7 rapid random values, then the final result
//  • Haptic feedback on roll start and finish
//  • "You rolled  4" large-number display
//  • Roll count pill (e.g. "3 rolls total")
//  • Animated Roll button with per-face gradient + glow shadow
//  • Clear history button
//  • History tab  — last 20 rolls with fade-in animation
//  • Statistics tab — animated frequency bar per face + %
//  • Ambient color blob behind the dice stage
//  • Dark background #0D0F1A, Poppins font throughout
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── App Entry Point ────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — same as the Expo app's orientation: "portrait"
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Light status bar icons on the dark background (#0D0F1A)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DiceApp());
}

// ─── Root Widget ─────────────────────────────────────────────
class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Roller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', // Apply Poppins everywhere
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.primary,
        ),
      ),
      home: const DiceScreen(),
    );
  }
}

// ─── Color Palette ────────────────────────────────────────────
// Mirrors constants/colors.ts from the original Expo project
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0F1A);
  static const Color surface = Color(0xFF161928);
  static const Color surfaceElevated = Color(0xFF1E2235);

  // Borders & text
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60% white
  static const Color textMuted = Color(0x59FFFFFF); // 35% white

  // Accent colors — same as FACE_COLORS in the original
  static const Color primary =
      Color(0xFF4F9EFF); // face 2 — blue (used for stat bars default)
  static const Color accent = Color(0xFFFF4F6E); // face 1 — pink/red
}

// Per-face accent colors (matches FACE_COLORS in the Expo app exactly)
const Map<int, Color> faceColors = {
  1: Color(0xFFFF5B79), // pink-red
  2: Color(0xFF4F9EFF), // blue
  3: Color(0xFFA78BFA), // purple
  4: Color(0xFF34D399), // green
  5: Color(0xFFFB923C), // orange
  6: Color(0xFF00D4FF), // cyan
};

// ─── Roll History Entry ───────────────────────────────────────
class RollEntry {
  final String id;
  final int value;
  final DateTime timestamp;

  RollEntry({required this.id, required this.value, required this.timestamp});
}

// ─── Main Screen ──────────────────────────────────────────────
class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with TickerProviderStateMixin {
  // ── Core State ───────────────────────────────────────────
  int _currentValue = 1; // Dice face shown (1–6)
  bool _isRolling = false; // True during roll animation
  final List<RollEntry> _history = []; // Roll history (newest first)
  final Map<int, int> _stats = {
    // Roll frequency per face
    1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0
  };
  String _activeTab = 'history'; // 'history' | 'stats'
  final Random _random = Random();
  late final AudioPlayer _rollAudioPlayer;
  bool _rollSoundPrepared = false;

  // ── Dice Animation Controller ─────────────────────────────
  late AnimationController _diceController;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  // ── Button Scale Animation ────────────────────────────────
  late AnimationController _btnController;
  late Animation<double> _btnScaleAnim;

  // ── Cycling timer (rapid random values before final result)
  Timer? _cycleTimer;
  int _cycleCount = 0;

  @override
  void initState() {
    super.initState();
    _rollAudioPlayer = AudioPlayer(playerId: 'roll_sfx');
    unawaited(_rollAudioPlayer.setReleaseMode(ReleaseMode.stop));
    unawaited(_rollAudioPlayer.setVolume(1.0));
    unawaited(_configureRollAudio());

    // Dice roll animation — 420 ms, matches Expo timing (350 + 70 ms)
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // One full rotation (same as Expo's withTiming(360, 350ms))
    _rotateAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _diceController, curve: Curves.easeOut),
    );

    // Scale: shrink → pop → settle  (mirrors Expo sequence)
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.72)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 52,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 31,
      ),
    ]).animate(_diceController);

    // Opacity: flash to 20% then back to 100%
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 0.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 83,
      ),
    ]).animate(_diceController);

    // Button press animation
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScaleAnim = _btnController.drive(Tween(begin: 0.94, end: 1.0));
  }

  @override
  void dispose() {
    _diceController.dispose();
    _btnController.dispose();
    _cycleTimer?.cancel();
    _rollAudioPlayer.dispose();
    super.dispose();
  }

  // ── Roll Logic ────────────────────────────────────────────
  // Mirrors the cycleFn in the original Expo app:
  //  • 7 rapid random values (every 55 ms) for visual drama
  //  • Then sets the final value and records it in history/stats
  void _rollDice() {
    if (_isRolling) return;

    HapticFeedback.heavyImpact(); // matches ImpactFeedbackStyle.Heavy
    setState(() => _isRolling = true);

    _cycleCount = 0;

    // Kick off the rapid cycling loop
    _cycle();
  }

  void _cycle() {
    _diceController.forward(from: 0); // play spin animation
    _playRollTickSound();

    setState(() {
      _currentValue = _random.nextInt(6) + 1; // show random face
    });

    _cycleCount++;

    if (_cycleCount < 7) {
      // Continue cycling every 55 ms (same as Expo's setTimeout 55ms)
      _cycleTimer = Timer(const Duration(milliseconds: 55), _cycle);
    } else {
      // Final value — record it after 55 ms
      _cycleTimer = Timer(const Duration(milliseconds: 55), () {
        final int finalValue = _random.nextInt(6) + 1;
        final String id = DateTime.now().millisecondsSinceEpoch.toString() +
            _random.nextDouble().toString();

        HapticFeedback.vibrate(); // matches NotificationFeedbackType.Success

        setState(() {
          _currentValue = finalValue;
          _isRolling = false;
          _stats[finalValue] = (_stats[finalValue] ?? 0) + 1;
          _history.insert(
            0,
            RollEntry(id: id, value: finalValue, timestamp: DateTime.now()),
          );
          // Keep last 20 entries
          if (_history.length > 20) _history.removeLast();
        });
      });
    }
  }

  // ── Clear History ─────────────────────────────────────────
  void _clearHistory() {
    HapticFeedback.lightImpact();
    setState(() {
      _history.clear();
      for (int i = 1; i <= 6; i++) {
        _stats[i] = 0;
      }
    });
  }

  Future<void> _confirmAndClearHistory() async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Clear history?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: const Text(
                'This will remove all roll history and statistics.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: faceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted || !shouldClear) return;
    _clearHistory();
  }

  void _playRollTickSound() {
    unawaited(
      _playAssetSound(
        player: _rollAudioPlayer,
        assetPath: 'sounds/ludo_roll.mp3',
        fallback: SystemSoundType.click,
      ),
    );
  }

  Future<void> _configureRollAudio() async {
    try {
      await _rollAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}

    try {
      await _rollAudioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
    } catch (_) {}

    try {
      await _rollAudioPlayer.setSource(AssetSource('sounds/ludo_roll.mp3'));
      _rollSoundPrepared = true;
    } catch (_) {
      _rollSoundPrepared = false;
    }
  }

  Future<void> _playAssetSound({
    required AudioPlayer player,
    required String assetPath,
    required SystemSoundType fallback,
  }) async {
    try {
      if (_rollSoundPrepared) {
        await player.stop();
        await player.resume();
      } else {
        await player.stop();
        await player.play(AssetSource(assetPath));
      }
    } catch (_) {
      await SystemSound.play(fallback);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  int get totalRolls => _history.length;
  int get maxCount => _stats.values.isEmpty ? 0 : _stats.values.reduce(max);
  Color get faceColor => faceColors[_currentValue]!;

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Deep gradient background ──────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0D1C),
                  Color(0xFF0D1120),
                  Color(0xFF0D0F1A)
                ],
              ),
            ),
          ),

          // ── Ambient color blob behind dice ────────────────
          // Changes color per face (same as <View ambientGlow> in Expo)
          _buildAmbientGlow(),

          // ── Main scrollable content ───────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: safePad.top + 8,
              bottom: safePad.bottom + 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                _buildHeader(),
                if (totalRolls > 0) _buildRollPill(),
                _buildDiceStage(),
                _buildRollButton(),
                if (totalRolls == 0) _buildTapHint(),
                if (totalRolls > 0) _buildClearButton(),
                if (totalRolls > 0) _buildPanel(),
                if (totalRolls == 0) _buildEmptyState(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget: Ambient Glow Blob ─────────────────────────────
  Widget _buildAmbientGlow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * 0.7;

    return Positioned(
      top: 80,
      left: screenWidth * 0.15,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: faceColor.withOpacity(0.07), // same opacity: 0.07 as Expo
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Widget: Header ────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.casino_outlined, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 8),
          const Text(
            'Dice Roller',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget: Roll Count Pill ───────────────────────────────
  // e.g. "3 rolls total" — shown only after ≥1 roll
  Widget _buildRollPill() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: faceColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: faceColor.withOpacity(0.27)),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: faceColor,
        ),
        child: Text('$totalRolls ${totalRolls == 1 ? "roll" : "rolls"} total'),
      ),
    );
  }

  // ── Widget: Dice Stage ────────────────────────────────────
  Widget _buildDiceStage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final diceSize = min(screenWidth * 0.52, 220.0);

    return Column(
      children: [
        SizedBox(
          width: diceSize + 60,
          height: diceSize + 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring — animated border color per face
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: diceSize + 48,
                height: diceSize + 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: faceColor.withOpacity(0.27),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: faceColor.withOpacity(0.22),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Platform disc gradient beneath the dice
              Positioned(
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: diceSize * 1.2,
                  height: diceSize * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(diceSize * 0.6),
                    gradient: LinearGradient(
                      colors: [
                        faceColor.withOpacity(0.094),
                        faceColor.withOpacity(0.031),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // The animated dice + tappable
              GestureDetector(
                onTap: _rollDice,
                child: AnimatedBuilder(
                  animation: _diceController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Opacity(
                          opacity: _opacityAnim.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dice face image
                      SizedBox(
                        width: diceSize,
                        height: diceSize,
                        child: Image.asset(
                          'assets/images/$_currentValue.png',
                          fit: BoxFit.contain,
                          // Fallback if image not found: draw pip dots
                          errorBuilder: (context, error, stackTrace) {
                            return CustomPaint(
                              painter: FallbackDicePainter(
                                value: _currentValue,
                                color: faceColor,
                              ),
                            );
                          },
                        ),
                      ),

                      // Drop shadow under dice
                      Positioned(
                        bottom: -8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: diceSize * 0.7,
                          height: 12,
                          decoration: BoxDecoration(
                            color: faceColor.withOpacity(0.19),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // "You rolled  4" value display
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _isRolling ? 'Rolling…' : 'You rolled',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (!_isRolling) ...[
              const SizedBox(width: 10),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 44,
                  height: 1.14,
                  color: faceColor,
                ),
                child: Text('$_currentValue'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Widget: Roll Button ───────────────────────────────────
  Widget _buildRollButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTapDown: (_) => _btnController.reverse(), // scale down
        onTapUp: (_) {
          _btnController.forward(); // scale back up
          _rollDice();
        },
        onTapCancel: () => _btnController.forward(),
        child: ScaleTransition(
          scale: _btnScaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _isRolling
                  ? const LinearGradient(
                      colors: [AppColors.surfaceElevated, AppColors.surface])
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [faceColor, faceColor.withOpacity(0.73)],
                    ),
              boxShadow: _isRolling
                  ? []
                  : [
                      BoxShadow(
                        color: faceColor.withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 52),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino,
                    size: 20,
                    color: _isRolling ? AppColors.textMuted : Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isRolling ? 'Rolling…' : 'Roll Dice',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: _isRolling ? AppColors.textMuted : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget: Tap Hint (before first roll) ─────────────────
  Widget _buildTapHint() {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Text(
        'or tap the dice above',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  // ── Widget: Clear History Button ──────────────────────────
  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _confirmAndClearHistory,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_outline, size: 13, color: AppColors.textMuted),
            SizedBox(width: 5),
            Text(
              'Clear history',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget: History + Stats Panel ────────────────────────
  Widget _buildPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Tab row
          _buildTabRow(),

          // Tab content
          if (_activeTab == 'history') _buildHistoryList(),
          if (_activeTab == 'stats') _buildStatsPanel(),
        ],
      ),
    );
  }

  // Tab switcher row
  Widget _buildTabRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final tab in ['history', 'stats'])
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activeTab = tab);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            _activeTab == tab ? faceColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab == 'history'
                            ? Icons.access_time_outlined
                            : Icons.bar_chart,
                        size: 15,
                        color:
                            _activeTab == tab ? faceColor : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: _activeTab == tab
                              ? faceColor
                              : AppColors.textMuted,
                        ),
                        child:
                            Text(tab == 'history' ? 'History' : 'Statistics'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── History List ──────────────────────────────────────────
  Widget _buildHistoryList() {
    final shown = _history.take(10).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++)
            _HistoryItemWidget(entry: shown[i]),
          if (_history.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '+ ${_history.length - 10} more',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // ── Statistics Panel ──────────────────────────────────────
  Widget _buildStatsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // Column headers
          Row(
            children: const [
              Text(
                'FACE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FREQUENCY',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'COUNT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // One bar per face
          for (int num = 1; num <= 6; num++)
            _StatBarWidget(
              num: num,
              count: _stats[num] ?? 0,
              maxCount: maxCount,
              totalRolls: totalRolls,
            ),

          // Footer hint
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Expected ~16.7% per face',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      width: double.infinity,
      child: Column(
        children: const [
          Icon(Icons.casino_outlined, size: 28, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'Your roll history will appear here',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── History Item Widget ──────────────────────────────────────
// Animated fade-in + slide-up when a new entry appears.
// Mirrors the HistoryItem component in the Expo app.
class _HistoryItemWidget extends StatefulWidget {
  final RollEntry entry;
  const _HistoryItemWidget({required this.entry});

  @override
  State<_HistoryItemWidget> createState() => _HistoryItemWidgetState();
}

class _HistoryItemWidgetState extends State<_HistoryItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: -10.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = faceColors[widget.entry.value]!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: _slideAnim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Colored badge showing the dice value
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.33)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.133),
                      color.withOpacity(0.039)
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.entry.value}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // "Rolled a 4"
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Rolled a '),
                    TextSpan(
                      text: '${widget.entry.value}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Timestamp (HH:MM)
              Text(
                '${widget.entry.timestamp.hour.toString().padLeft(2, '0')}:'
                '${widget.entry.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Bar Widget ─────────────────────────────────────────
// Animated frequency bar per dice face (1–6).
// Mirrors the StatBar component in the Expo app.
class _StatBarWidget extends StatefulWidget {
  final int num;
  final int count;
  final int maxCount;
  final int totalRolls;

  const _StatBarWidget({
    required this.num,
    required this.count,
    required this.maxCount,
    required this.totalRolls,
  });

  @override
  State<_StatBarWidget> createState() => _StatBarWidgetState();
}

class _StatBarWidgetState extends State<_StatBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _widthAnim; // 0.0 → percentage fill

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _widthAnim = Tween<double>(begin: 0, end: _targetWidth).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  double get _targetWidth {
    if (widget.maxCount == 0) return 0;
    return widget.count / widget.maxCount;
  }

  @override
  void didUpdateWidget(_StatBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smoothly animate bar to new width whenever count changes
    _widthAnim = Tween<double>(
      begin: _widthAnim.value,
      end: _targetWidth,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = faceColors[widget.num]!;
    final percentage = widget.totalRolls > 0
        ? (widget.count / widget.totalRolls * 100).toStringAsFixed(0)
        : '0';
    // "Hot" face = the one with most rolls
    final isHot = widget.count == widget.maxCount && widget.count > 0;
    final displayColor = isHot ? color : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Face number badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: displayColor.withOpacity(0.33)),
              color: displayColor.withOpacity(0.094),
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.num}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: displayColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Animated frequency bar track
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 7,
                color: AppColors.surfaceElevated,
                alignment: Alignment.centerLeft,
                child: AnimatedBuilder(
                  animation: _widthAnim,
                  builder: (context, _) {
                    return FractionallySizedBox(
                      widthFactor: _widthAnim.value,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Count + percentage
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isHot ? displayColor : AppColors.text,
                    height: 1.23,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textMuted,
                    height: 1.3,
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

// ─── Fallback Dice Painter ────────────────────────────────────
// Draws pip dots on canvas when dice_X.png is missing.
// Uses the per-face accent color for the pips.
class FallbackDicePainter extends CustomPainter {
  final int value;
  final Color color;

  const FallbackDicePainter({required this.value, required this.color});

  static const Map<int, List<List<int>>> _pips = {
    1: [
      [1, 1]
    ],
    2: [
      [0, 0],
      [2, 2]
    ],
    3: [
      [0, 0],
      [1, 1],
      [2, 2]
    ],
    4: [
      [0, 0],
      [0, 2],
      [2, 0],
      [2, 2]
    ],
    5: [
      [0, 0],
      [0, 2],
      [1, 1],
      [2, 0],
      [2, 2]
    ],
    6: [
      [0, 0],
      [0, 2],
      [1, 0],
      [1, 2],
      [2, 0],
      [2, 2]
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    // Dice card background
    final bgPaint = Paint()..color = AppColors.surface;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.15),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = color.withOpacity(0.33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Pip dots
    final pipPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final cellW = size.width / 3;
    final cellH = size.height / 3;
    final pipR = size.width * 0.09;
    final padding = size.width * 0.12;

    for (final pos in _pips[value] ?? []) {
      final col = pos[1];
      final row = pos[0];
      final cx = padding + col * cellW + cellW / 2;
      final cy = padding + row * cellH + cellH / 2;
      canvas.drawCircle(Offset(cx, cy), pipR, pipPaint);
    }
  }

  @override
  bool shouldRepaint(FallbackDicePainter old) =>
      old.value != value || old.color != color;
}
