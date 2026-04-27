import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class _Tip {
  final IconData icon;
  final String text;
  const _Tip(this.icon, this.text);
}

const _tips = <_Tip>[
  _Tip(FeatherIcons.droplet,
      'Drink at least 8 glasses of water daily to support your metabolism.'),
  _Tip(FeatherIcons.activity,
      'Aim for 150 minutes of moderate aerobic activity per week.'),
  _Tip(FeatherIcons.sun,
      'Eat a rainbow of vegetables to get diverse, essential nutrients.'),
  _Tip(FeatherIcons.moon,
      'Quality sleep (7-9 hours) helps regulate hunger hormones like ghrelin.'),
  _Tip(FeatherIcons.zap,
      'Strength training 2-3x per week preserves muscle mass as you age.'),
  _Tip(FeatherIcons.xCircle,
      'Reduce ultra-processed foods to manage weight more effectively.'),
  _Tip(FeatherIcons.book,
      'Track your meals to become more mindful of calorie intake.'),
  _Tip(FeatherIcons.trendingUp,
      'Take stairs instead of elevators for extra daily movement.'),
  _Tip(FeatherIcons.heart,
      'Manage stress levels - chronic stress can lead to weight gain.'),
  _Tip(FeatherIcons.clock,
      'Eat slowly and mindfully; it takes 20 mins for fullness signals to kick in.'),
];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class HealthTip extends StatelessWidget {
  const HealthTip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final now = DateTime.now();
    final tip = _tips[now.day % _tips.length];
    final today = '${_months[now.month - 1]} ${now.day}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.047),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.133), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.094),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(FeatherIcons.zap,
                    size: 13, color: colors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Tip',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.078),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FeatherIcons.calendar,
                        size: 10, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      today,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.125), width: 1.5),
                ),
                child: Icon(tip.icon, size: 16, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    tip.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 21 / 14,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
