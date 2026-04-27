import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/bmi_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/bmi_utils.dart';
import '../utils/conversions.dart';
import '../widgets/bmi_result_display.dart';
import '../widgets/bmi_spinner.dart';
import '../widgets/gender_selector.dart';
import '../widgets/health_tip.dart';
import '../widgets/metric_card.dart';
import '../widgets/unit_toggle.dart';

enum _Stage { input, loading, result }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  _Stage _stage = _Stage.input;
  HeightUnit _heightUnit = HeightUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;

  late final ScrollController _scrollCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _resultCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _btnCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  void _onUnitSystemChange(UnitSystem u) {
    final p = context.read<BMIProvider>();
    p.setUnitSystem(u);
    setState(() {
      if (u == UnitSystem.imperial) {
        _heightUnit = HeightUnit.ftIn;
        _weightUnit = WeightUnit.lbs;
      } else {
        _heightUnit = HeightUnit.cm;
        _weightUnit = WeightUnit.kg;
      }
    });
  }

  void _onCalculate() {
    HapticFeedback.mediumImpact();
    _btnCtrl.value = 0.93;
    _btnCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack);
    context.read<BMIProvider>().saveBMIRecord();
    setState(() => _stage = _Stage.loading);
  }

  void _onSpinnerDone() {
    setState(() => _stage = _Stage.result);
    _resultCtrl.forward(from: 0);
  }

  void _onReset() {
    HapticFeedback.mediumImpact();
    context.read<BMIProvider>().resetInputs();
  }

  void _onEditInputs() {
    HapticFeedback.lightImpact();
    setState(() => _stage = _Stage.input);
    _scrollToTop();
  }

  void _onCalculateNew() {
    HapticFeedback.mediumImpact();
    context.read<BMIProvider>().resetInputs();
    setState(() => _stage = _Stage.input);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final bmiP = context.watch<BMIProvider>();
    final bmi = bmiP.bmi;
    final bmiColor =
        bmi > 0 ? getBMIColorForPalette(colors, bmi) : colors.primary;

    final media = MediaQuery.of(context);
    final topPad = media.padding.top + 16;
    final bottomPad = media.padding.bottom + 84 + 16;

    final ideal = getIdealWeight(bmiP.heightCm);
    final idealDisp = _weightUnit == WeightUnit.lbs
        ? IdealWeight(kgToLbs(ideal.min).roundToDouble(),
            kgToLbs(ideal.max).roundToDouble())
        : ideal;
    final calories =
        getCalories(bmiP.weightKg, bmiP.heightCm, bmiP.age, bmiP.gender);

    return Stack(
      children: [
        Container(color: colors.background),
        SafeArea(
          bottom: false,
          child: IgnorePointer(
            ignoring: _stage == _Stage.loading,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(18, topPad, 18, bottomPad),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BMI',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              height: 42 / 40,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              color: colors.foreground,
                            ),
                          ),
                          Text(
                            'Calculator',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              height: 42 / 40,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              color: colors.foreground.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your health journey',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    UnitToggle(
                      value: bmiP.unitSystem,
                      onChange: _onUnitSystemChange,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_stage != _Stage.result) ...[
                  // Gender section
                  _section(
                    colors: colors,
                    accentDot: colors.primary,
                    title: 'Gender',
                    child: GenderSelector(
                      value: bmiP.gender,
                      onChange: (g) => bmiP.setGender(g),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Measurements
                  _section(
                    colors: colors,
                    accentDot: colors.primary,
                    title: 'Measurements',
                    trailing: _resetPill(colors, _onReset),
                    child: Column(
                      children: [
                        MetricCard(
                          type: MetricCardType.height,
                          heightCm: bmiP.heightCm,
                          weightKg: bmiP.weightKg,
                          age: bmiP.age,
                          heightUnit: _heightUnit,
                          weightUnit: _weightUnit,
                          accentColor: const Color(0xFF7C3AED),
                          onHeightCmChange: bmiP.setHeightCm,
                          onHeightUnitChange: (u) =>
                              setState(() => _heightUnit = u),
                          onClear: () => bmiP.setHeightCm(170),
                        ),
                        const SizedBox(height: 14),
                        MetricCard(
                          type: MetricCardType.weight,
                          heightCm: bmiP.heightCm,
                          weightKg: bmiP.weightKg,
                          age: bmiP.age,
                          heightUnit: _heightUnit,
                          weightUnit: _weightUnit,
                          accentColor: const Color(0xFFA855F7),
                          onWeightKgChange: bmiP.setWeightKg,
                          onWeightUnitChange: (u) =>
                              setState(() => _weightUnit = u),
                          onClear: () => bmiP.setWeightKg(70),
                        ),
                        const SizedBox(height: 14),
                        MetricCard(
                          type: MetricCardType.age,
                          heightCm: bmiP.heightCm,
                          weightKg: bmiP.weightKg,
                          age: bmiP.age,
                          heightUnit: _heightUnit,
                          weightUnit: _weightUnit,
                          accentColor: const Color(0xFFEC4899),
                          onAgeChange: bmiP.setAge,
                          onClear: () => bmiP.setAge(25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Calculate button
                  ScaleTransition(
                    scale: _btnCtrl,
                    child: GestureDetector(
                      onTap: _onCalculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.35),
                              offset: const Offset(0, 10),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FeatherIcons.zap,
                                size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Calculate BMI',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const HealthTip(),
                ],

                if (_stage == _Stage.result && bmi > 0) ...[
                  AnimatedBuilder(
                    animation: _resultCtrl,
                    builder: (_, child) {
                      return Opacity(
                        opacity: _resultCtrl.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _resultCtrl.value) * 30),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: bmiColor.withAlpha(0x30),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                offset: const Offset(0, 3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: bmiColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your BMI Result',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colors.foreground,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bmiColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      getBMICategory(bmi),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: bmiColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              BMIResultDisplay(bmi: bmi),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.muted,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(FeatherIcons.messageCircle,
                                        size: 14,
                                        color: colors.mutedForeground),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        getBMIMessage(bmi),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          color: colors.foreground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _resultActionButton(
                                      colors: colors,
                                      label: 'Calculate New',
                                      icon: FeatherIcons.refreshCcw,
                                      onTap: _onCalculateNew,
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _resultActionButton(
                                      colors: colors,
                                      label: 'Edit Inputs',
                                      icon: FeatherIcons.edit2,
                                      onTap: _onEditInputs,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stats grid
                        LayoutBuilder(builder: (context, c) {
                          final tileW = (c.maxWidth - 10) / 2;
                          final tiles = [
                            _Tile(
                              icon: FeatherIcons.target,
                              color: const Color(0xFF7C3AED),
                              label: 'Ideal Weight (${_weightUnit.short})',
                              value:
                                  '${_fmtNum(idealDisp.min)}-${_fmtNum(idealDisp.max)}',
                            ),
                            _Tile(
                              icon: FeatherIcons.zap,
                              color: const Color(0xFFEC4899),
                              label: 'Est. Calories/day',
                              value: '$calories',
                            ),
                            _Tile(
                              icon: FeatherIcons.trendingUp,
                              color: bmiColor,
                              label: 'BMI Score',
                              value: bmi.toStringAsFixed(1),
                            ),
                            _Tile(
                              icon: FeatherIcons.shield,
                              color: bmiColor,
                              label: 'Category',
                              value: getBMICategory(bmi),
                            ),
                          ];
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final t in tiles)
                                SizedBox(
                                    width: tileW,
                                    child: _statTile(colors, t)),
                            ],
                          );
                        }),
                        const SizedBox(height: 14),
                        const HealthTip(),
                      ],
                    ),
                  ),
                ],
                ],
              ),
            ),
          ),
        ),
        if (_stage == _Stage.loading)
          BMISpinner(onDone: _onSpinnerDone, durationMs: 3000),
      ],
    );
  }

  String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _resultActionButton({
    required dynamic colors,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? colors.primary : colors.muted,
          borderRadius: BorderRadius.circular(16),
          border: primary
              ? null
              : Border.all(color: colors.border, width: 1.5),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.24),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: primary ? Colors.white : colors.foreground,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required dynamic colors,
    required Color accentDot,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: accentDot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _resetPill(dynamic colors, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FeatherIcons.refreshCcw,
                  size: 11, color: colors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                'Reset all',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statTile(dynamic colors, _Tile t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.color.withValues(alpha: 0.16), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.094),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(t.icon, size: 13, color: t.color),
          ),
          const SizedBox(height: 8),
          Text(
            t.value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Tile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
}
