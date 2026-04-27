import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/bmi_provider.dart';
import '../providers/theme_provider.dart';

class UnitToggle extends StatelessWidget {
  final UnitSystem value;
  final ValueChanged<UnitSystem> onChange;
  const UnitToggle({super.key, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: UnitSystem.values.map((u) {
          final active = u == value;
          return Padding(
            padding: EdgeInsets.only(
              right: u == UnitSystem.values.last ? 0 : 2,
            ),
            child: GestureDetector(
              onTap: () {
                if (!active) {
                  HapticFeedback.lightImpact();
                  onChange(u);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
                child: Text(
                  u == UnitSystem.metric ? 'cm/kg' : 'ft/lbs',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : colors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
