import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class GenderSelector extends StatefulWidget {
  final String value; // 'male' | 'female'
  final ValueChanged<String> onChange;
  const GenderSelector({super.key, required this.value, required this.onChange});

  @override
  State<GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<GenderSelector>
    with TickerProviderStateMixin {
  late final AnimationController _maleCtrl;
  late final AnimationController _femaleCtrl;
  late final Animation<double> _maleScale;
  late final Animation<double> _femaleScale;

  @override
  void initState() {
    super.initState();
    _maleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
        value: 1.0,
        lowerBound: 0.85,
        upperBound: 1.0);
    _femaleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
        value: 1.0,
        lowerBound: 0.85,
        upperBound: 1.0);
    _maleScale = CurvedAnimation(parent: _maleCtrl, curve: Curves.easeOutBack);
    _femaleScale =
        CurvedAnimation(parent: _femaleCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    super.dispose();
  }

  void _pick(String g, AnimationController c) {
    HapticFeedback.mediumImpact();
    c.value = 0.9;
    c.animateTo(1.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack);
    widget.onChange(g);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final genders = [
      {
        'id': 'male',
        'label': 'Male',
        'icon': FeatherIcons.user,
        'color': colors.male,
      },
      {
        'id': 'female',
        'label': 'Female',
        'icon': FeatherIcons.users,
        'color': colors.female,
      },
    ];

    return Row(
      children: [
        for (int i = 0; i < genders.length; i++) ...[
          Expanded(
            child: _buildCard(
              context,
              colors,
              genders[i]['id'] as String,
              genders[i]['label'] as String,
              genders[i]['icon'] as IconData,
              genders[i]['color'] as Color,
            ),
          ),
          if (i == 0) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, dynamic colors, String id,
      String label, IconData icon, Color color) {
    final selected = widget.value == id;
    final scale = id == 'male' ? _maleScale : _femaleScale;
    final ctrl = id == 'male' ? _maleCtrl : _femaleCtrl;

    return ScaleTransition(
      scale: scale,
      child: GestureDetector(
        onTap: () => _pick(id, ctrl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : colors.border,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    selected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected ? color : colors.muted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.25)
                            : colors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon,
                        size: 22,
                        color: selected ? Colors.white : colors.mutedForeground),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      letterSpacing: 0.2,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
