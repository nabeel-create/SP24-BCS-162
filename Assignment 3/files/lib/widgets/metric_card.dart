import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/conversions.dart';
import 'ruler_picker.dart';

enum MetricCardType { height, weight, age }

enum HeightUnit { cm, m, ftIn }

enum WeightUnit { kg, lbs, st }

extension HUStr on HeightUnit {
  String get short => this == HeightUnit.cm
      ? 'cm'
      : this == HeightUnit.m
          ? 'm'
          : 'ft+in';
}

extension WUStr on WeightUnit {
  String get short => this == WeightUnit.kg
      ? 'kg'
      : this == WeightUnit.lbs
          ? 'lbs'
          : 'st';
}

class _RulerConfig {
  final double min, max, step, value;
  final int majorEvery, labelEvery;
  const _RulerConfig({
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.majorEvery,
    required this.labelEvery,
  });
}

class MetricCard extends StatefulWidget {
  final MetricCardType type;
  final int heightCm;
  final double weightKg;
  final int age;
  final HeightUnit heightUnit;
  final WeightUnit weightUnit;
  final Color accentColor;
  final ValueChanged<int>? onHeightCmChange;
  final ValueChanged<double>? onWeightKgChange;
  final ValueChanged<int>? onAgeChange;
  final ValueChanged<HeightUnit>? onHeightUnitChange;
  final ValueChanged<WeightUnit>? onWeightUnitChange;
  final VoidCallback? onClear;

  const MetricCard({
    super.key,
    required this.type,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.heightUnit,
    required this.weightUnit,
    required this.accentColor,
    this.onHeightCmChange,
    this.onWeightKgChange,
    this.onAgeChange,
    this.onHeightUnitChange,
    this.onWeightUnitChange,
    this.onClear,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focus.hasFocus && _editing) {
      _commitKeyboard();
    }
  }

  _RulerConfig _rulerConfig() {
    switch (widget.type) {
      case MetricCardType.height:
        if (widget.heightUnit == HeightUnit.cm ||
            widget.heightUnit == HeightUnit.m) {
          return _RulerConfig(
            min: 100,
            max: 220,
            step: 1,
            value: widget.heightCm.toDouble(),
            majorEvery: 5,
            labelEvery: 10,
          );
        }
        final totalIn = (widget.heightCm / 2.54).round();
        return _RulerConfig(
          min: 48,
          max: 96,
          step: 1,
          value: totalIn.toDouble(),
          majorEvery: 6,
          labelEvery: 12,
        );
      case MetricCardType.weight:
        if (widget.weightUnit == WeightUnit.kg) {
          return _RulerConfig(
            min: 20,
            max: 200,
            step: 1,
            value: widget.weightKg.round().toDouble(),
            majorEvery: 5,
            labelEvery: 10,
          );
        }
        if (widget.weightUnit == WeightUnit.lbs) {
          return _RulerConfig(
            min: 44,
            max: 441,
            step: 1,
            value: kgToLbs(widget.weightKg).round().toDouble(),
            majorEvery: 10,
            labelEvery: 20,
          );
        }
        final st = (kgToSt(widget.weightKg) * 10).round() / 10;
        return _RulerConfig(
          min: 3,
          max: 32,
          step: 0.5,
          value: st,
          majorEvery: 2,
          labelEvery: 4,
        );
      case MetricCardType.age:
        return _RulerConfig(
          min: 1,
          max: 120,
          step: 1,
          value: widget.age.toDouble(),
          majorEvery: 5,
          labelEvery: 10,
        );
    }
  }

  String _formatDisplay() {
    switch (widget.type) {
      case MetricCardType.height:
        if (widget.heightUnit == HeightUnit.cm) {
          return '${widget.heightCm}';
        }
        if (widget.heightUnit == HeightUnit.m) {
          return cmToM(widget.heightCm).toStringAsFixed(2);
        }
        final ft = cmToFtIn(widget.heightCm);
        return "${ft.feet}' ${ft.inches}\"";
      case MetricCardType.weight:
        if (widget.weightUnit == WeightUnit.kg) {
          final v = (widget.weightKg * 10).round() / 10;
          return v % 1 == 0 ? v.toInt().toString() : v.toString();
        }
        if (widget.weightUnit == WeightUnit.lbs) {
          return kgToLbs(widget.weightKg).round().toString();
        }
        return kgToSt(widget.weightKg).toStringAsFixed(1);
      case MetricCardType.age:
        return '${widget.age}';
    }
  }

  String _displayUnit() {
    switch (widget.type) {
      case MetricCardType.height:
        return widget.heightUnit == HeightUnit.ftIn ? '' : widget.heightUnit.short;
      case MetricCardType.weight:
        return widget.weightUnit.short;
      case MetricCardType.age:
        return 'yrs';
    }
  }

  void _onRulerChange(double v) {
    switch (widget.type) {
      case MetricCardType.height:
        if (widget.heightUnit == HeightUnit.cm ||
            widget.heightUnit == HeightUnit.m) {
          widget.onHeightCmChange?.call(v.round());
        } else {
          widget.onHeightCmChange?.call((v * 2.54).round());
        }
        break;
      case MetricCardType.weight:
        if (widget.weightUnit == WeightUnit.kg) {
          widget.onWeightKgChange?.call((v * 10).round() / 10);
        } else if (widget.weightUnit == WeightUnit.lbs) {
          widget.onWeightKgChange?.call((lbsToKg(v) * 10).round() / 10);
        } else {
          widget.onWeightKgChange?.call((stToKg(v) * 10).round() / 10);
        }
        break;
      case MetricCardType.age:
        widget.onAgeChange?.call(v.round());
        break;
    }
  }

  void _openKeyboard() {
    HapticFeedback.lightImpact();
    final txt = _formatDisplay().replaceAll(RegExp(r'''['"\s]'''), '');
    _ctrl.text = txt;
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: txt.length);
    setState(() => _editing = true);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commitKeyboard() {
    setState(() => _editing = false);
    final parsed = double.tryParse(_ctrl.text);
    if (parsed == null) return;
    switch (widget.type) {
      case MetricCardType.height:
        if (widget.heightUnit == HeightUnit.cm) {
          widget.onHeightCmChange
              ?.call(parsed.round().clamp(100, 250));
        } else if (widget.heightUnit == HeightUnit.m) {
          widget.onHeightCmChange
              ?.call(mToCm(parsed.clamp(1.0, 2.5)));
        } else {
          final ft = parsed.floor();
          final ins = ((parsed - ft) * 10).round();
          widget.onHeightCmChange
              ?.call(ftInToCm(ft, ins.clamp(0, 11)));
        }
        break;
      case MetricCardType.weight:
        double base = parsed;
        if (widget.weightUnit == WeightUnit.lbs) base = lbsToKg(parsed);
        if (widget.weightUnit == WeightUnit.st) base = stToKg(parsed);
        final v = ((base * 10).round() / 10).clamp(20.0, 300.0);
        widget.onWeightKgChange?.call(v);
        break;
      case MetricCardType.age:
        widget.onAgeChange?.call(parsed.round().clamp(1, 120));
        break;
    }
  }

  void _switchUnit(dynamic u) {
    HapticFeedback.lightImpact();
    if (widget.type == MetricCardType.height) {
      widget.onHeightUnitChange?.call(u as HeightUnit);
    } else {
      widget.onWeightUnitChange?.call(u as WeightUnit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final accent = widget.accentColor;
    final label = widget.type == MetricCardType.height
        ? 'HEIGHT'
        : widget.type == MetricCardType.weight
            ? 'WEIGHT'
            : 'AGE';
    final icon = widget.type == MetricCardType.height
        ? FeatherIcons.maximize2
        : widget.type == MetricCardType.weight
            ? FeatherIcons.disc
            : FeatherIcons.clock;

    final units = widget.type == MetricCardType.height
        ? HeightUnit.values.cast<dynamic>()
        : widget.type == MetricCardType.weight
            ? WeightUnit.values.cast<dynamic>()
            : <dynamic>[];
    final currentUnit = widget.type == MetricCardType.height
        ? widget.heightUnit
        : widget.type == MetricCardType.weight
            ? widget.weightUnit
            : null;

    final ruler = _rulerConfig();
    final dispVal = _formatDisplay();
    final unitLabel = _displayUnit();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _editing
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.04),
                colors.card,
              )
            : colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _editing ? accent : accent.withValues(alpha: 0.16),
          width: _editing ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _editing
                ? accent.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 4),
            blurRadius: _editing ? 18 : 14,
            spreadRadius: _editing ? 0.5 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: colors.mutedForeground,
                ),
              ),
              const Spacer(),
              if (widget.onClear != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onClear!();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
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
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Unit selector
          if (units.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < units.length; i++) ...[
                    GestureDetector(
                      onTap: () => _switchUnit(units[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: units[i] == currentUnit
                              ? accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          units[i] is HeightUnit
                              ? (units[i] as HeightUnit).short
                              : (units[i] as WeightUnit).short,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: units[i] == currentUnit
                                ? Colors.white
                                : colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    if (i < units.length - 1) const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Value display / keyboard
          GestureDetector(
            onTap: _openKeyboard,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_editing)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.7),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: false),
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          onSubmitted: (_) => _commitKeyboard(),
                          onTapOutside: (_) => _commitKeyboard(),
                          decoration: const InputDecoration(
                            counterText: '',
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            height: 56 / 52,
                            letterSpacing: -2,
                            color: accent,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      dispVal,
                      style: GoogleFonts.inter(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        height: 56 / 52,
                        letterSpacing: -2,
                        color: accent,
                      ),
                    ),
                  if (unitLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        unitLabel,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: accent.withValues(alpha: 0.44),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FeatherIcons.type, size: 11, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'type',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ruler
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.10)),
              color: accent.withValues(alpha: 0.024),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RulerPicker(
                value: ruler.value,
                min: ruler.min,
                max: ruler.max,
                step: ruler.step,
                accentColor: accent,
                majorEvery: ruler.majorEvery,
                labelEvery: ruler.labelEvery,
                onChange: _onRulerChange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Range labels
          Row(
            children: [
              Text(
                '${ruler.min.toStringAsFixed(0)}${widget.type == MetricCardType.age ? " yr" : ""}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '<- scroll to adjust ->',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${ruler.max.toStringAsFixed(0)}${widget.type == MetricCardType.age ? " yr" : ""}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
