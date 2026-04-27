import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/bmi_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/gender_selector.dart';

class _ThemeOption {
  final AppThemeMode value;
  final String label;
  final IconData icon;
  const _ThemeOption(this.value, this.label, this.icon);
}

const _themeOptions = [
  _ThemeOption(AppThemeMode.light, 'Light', FeatherIcons.sun),
  _ThemeOption(AppThemeMode.dark, 'Dark', FeatherIcons.moon),
  _ThemeOption(AppThemeMode.system, 'Auto', FeatherIcons.smartphone),
];

class _BmiInfo {
  final String range;
  final String label;
  final String tip;
  const _BmiInfo(this.range, this.label, this.tip);
}

const _bmiInfo = [
  _BmiInfo('< 18.5', 'Underweight', 'Consider gaining healthy weight.'),
  _BmiInfo('18.5 - 24.9', 'Normal', 'Keep up the great work!'),
  _BmiInfo('25 - 29.9', 'Overweight', 'Moderate diet & exercise.'),
  _BmiInfo('>= 30', 'Obese', 'Consult a healthcare professional.'),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: context.read<BMIProvider>().profile.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    context
        .read<BMIProvider>()
        .updateProfile(name: _name.text.trim());
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final bmiP = context.watch<BMIProvider>();
    final theme = context.watch<ThemeProvider>();
    final history = bmiP.history;
    final media = MediaQuery.of(context);
    final topPad = media.padding.top + 16;
    final bottomPad = media.padding.bottom + 84 + 16;

    final avgBMI = history.isEmpty
        ? null
        : history.fold<double>(0, (s, r) => s + r.bmi) / history.length;
    final bmiInfoColors = [
      colors.underweight,
      colors.normal,
      colors.overweight,
      colors.obese,
    ];

    return Container(
      color: colors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, topPad, 18, bottomPad),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'My',
              style: GoogleFonts.inter(
                fontSize: 40,
                height: 42 / 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                color: colors.foreground,
              ),
            ),
            Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 40,
                height: 42 / 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                color: colors.foreground.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 18),

            // Profile card
            _card(colors,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.094),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colors.primary.withValues(alpha: 0.188),
                                width: 2),
                          ),
                          child: Icon(FeatherIcons.user,
                              size: 28, color: colors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_editing)
                                TextField(
                                  controller: _name,
                                  autofocus: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: colors.foreground,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Your name',
                                    hintStyle: GoogleFonts.inter(
                                      color: colors.mutedForeground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: colors.primary, width: 2),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: colors.primary, width: 2),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: colors.primary, width: 2),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  bmiP.profile.name.isEmpty
                                      ? 'Tap to add name'
                                      : bmiP.profile.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: colors.foreground,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _metaPill(
                                      colors,
                                      FeatherIcons.activity,
                                      '${history.length} check${history.length == 1 ? "" : "s"}'),
                                  if (avgBMI != null)
                                    _metaPill(colors, FeatherIcons.barChart2,
                                        'Avg ${avgBMI.toStringAsFixed(1)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _editing ? _save() : setState(() => _editing = true),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _editing ? colors.primary : colors.muted,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              _editing ? FeatherIcons.check : FeatherIcons.edit2,
                              size: 15,
                              color:
                                  _editing ? Colors.white : colors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 14),
                      GenderSelector(
                          value: bmiP.profile.gender,
                          onChange: (g) =>
                              bmiP.updateProfile(gender: g)),
                    ],
                  ],
                )),
            const SizedBox(height: 14),

            // Appearance card
            _sectionCard(
              colors: colors,
              title: 'Appearance',
              child: Row(
                children: [
                  for (int i = 0; i < _themeOptions.length; i++) ...[
                    Expanded(
                      child: _themeButton(colors, theme, _themeOptions[i]),
                    ),
                    if (i < _themeOptions.length - 1)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // BMI Categories card
            _sectionCard(
              colors: colors,
              title: 'BMI Categories',
              child: Column(
                children: [
                  for (int i = 0; i < _bmiInfo.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: i < _bmiInfo.length - 1
                          ? BoxDecoration(
                              border: Border(
                                bottom:
                                    BorderSide(color: colors.border, width: 1),
                              ),
                            )
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 40,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: bmiInfoColors[i],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _bmiInfo[i].range,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.foreground,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: bmiInfoColors[i]
                                            .withValues(alpha: 0.094),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        border: Border.all(
                                            color: bmiInfoColors[i]
                                                .withValues(alpha: 0.188)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                                color: bmiInfoColors[i],
                                                shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _bmiInfo[i].label,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: bmiInfoColors[i],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(_bmiInfo[i].tip,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: colors.mutedForeground,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // About BMI card
            _sectionCard(
              colors: colors,
              title: 'About BMI',
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colors.primary.withValues(alpha: 0.125)),
                    ),
                    child: Center(
                      child: Text(
                        'BMI = weight (kg) / height^2 (m^2)',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'BMI is a screening tool, not a diagnostic measure. It estimates body fat based on height and weight. Consult a healthcare professional for personalized guidance.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 21 / 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(FeatherIcons.info,
                            size: 13, color: colors.mutedForeground),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'BMI may not be accurate for athletes, the elderly, or pregnant individuals.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 18 / 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(dynamic colors, {required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: child,
      );

  Widget _sectionCard(
      {required dynamic colors, required String title, required Widget child}) {
    return _card(colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: colors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ));
  }

  Widget _metaPill(dynamic colors, IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: colors.mutedForeground),
            const SizedBox(width: 4),
            Text(text,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                )),
          ],
        ),
      );

  Widget _themeButton(
      dynamic colors, ThemeProvider theme, _ThemeOption opt) {
    final active = theme.themeMode == opt.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        theme.setThemeMode(opt.value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              active ? colors.primary.withValues(alpha: 0.078) : colors.muted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? colors.primary.withValues(alpha: 0.27) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: active ? colors.primary : colors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(opt.icon,
                  size: 14,
                  color: active ? Colors.white : colors.mutedForeground),
            ),
            const SizedBox(height: 8),
            Text(
              opt.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                letterSpacing: 0.1,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? colors.primary : colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
