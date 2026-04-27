import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/bmi_record.dart';
import '../providers/bmi_provider.dart';
import '../providers/theme_provider.dart';
import 'admin_screen.dart';
import '../utils/bmi_utils.dart';
import '../widgets/bmi_history_chart.dart';
import '../widgets/dashed_panel.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final bmiP = context.watch<BMIProvider>();
    final history = bmiP.history;
    final media = MediaQuery.of(context);
    final topPad = media.padding.top + 16;
    final bottomPad = media.padding.bottom + 84 + 16;

    final reversed = history.reversed.toList();

    final avgBMI = history.isEmpty
        ? null
        : history.fold<double>(0, (s, r) => s + r.bmi) / history.length;
    final bestBMI = history.isEmpty
        ? null
        : history
            .reduce(
                (b, r) => (r.bmi - 22).abs() < (b.bmi - 22).abs() ? r : b)
            .bmi;

    return Container(
      color: colors.background,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(18, topPad, 18, bottomPad),
        itemCount: history.isEmpty ? 2 : reversed.length + 1,
        separatorBuilder: (_, i) =>
            i == 0 ? const SizedBox.shrink() : const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _header(
                context, colors, bmiP, history, avgBMI, bestBMI);
          }
          if (history.isEmpty) {
            return _empty(colors);
          }
          final realIndex = history.length - i;
          return _HistoryItem(
              item: reversed[i - 1], index: realIndex);
        },
      ),
    );
  }

  Widget _header(
    BuildContext context,
    dynamic colors,
    BMIProvider bmiP,
    List<BMIRecord> history,
    double? avgBMI,
    double? bestBMI,
  ) {
    final avgColor = avgBMI != null
        ? getBMIColorForPalette(colors, avgBMI)
        : colors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BMI',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          height: 42 / 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          color: colors.foreground,
                        )),
                    Text('History',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          height: 42 / 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          color: colors.foreground.withValues(alpha: 0.4),
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '${history.length} record${history.length == 1 ? "" : "s"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _adminButton(context, colors),
            ],
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                      colors,
                      label: 'Avg BMI',
                      value: avgBMI!.toStringAsFixed(1),
                      color: avgColor,
                      icon: FeatherIcons.activity),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(colors,
                      label: 'Best BMI',
                      value: bestBMI!.toStringAsFixed(1),
                      color: colors.normal,
                      icon: FeatherIcons.award),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(colors,
                      label: 'Total Checks',
                      value: '${history.length}',
                      color: colors.primary,
                      icon: FeatherIcons.calendar),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
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
                      Text('BMI Trend',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.foreground)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BMIHistoryChart(history: history),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: colors.mutedForeground, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('ALL RECORDS (NEWEST FIRST)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: colors.mutedForeground,
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(dynamic colors,
      {required String label,
      required String value,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.145), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.078),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: color,
              )),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.mutedForeground,
              )),
        ],
      ),
    );
  }

  Widget _adminButton(BuildContext context, dynamic colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FeatherIcons.shield,
              size: 13,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Admin',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      child: DashedPanel(
        padding: const EdgeInsets.all(36),
        borderRadius: BorderRadius.circular(24),
        color: colors.border,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(color: colors.muted, shape: BoxShape.circle),
              child: Icon(FeatherIcons.clock,
                  size: 32, color: colors.mutedForeground),
            ),
            const SizedBox(height: 14),
            Text('No Records Yet',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                )),
            const SizedBox(height: 8),
            Text(
              'Calculate your BMI on the home tab to start tracking your progress.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 21 / 14,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _HistoryItem extends StatelessWidget {
  final BMIRecord item;
  final int index;
  const _HistoryItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final date = DateTime.parse(item.date).toLocal();
    final bmiColor = getBMIColorForPalette(colors, item.bmi);
    final wd = _weekdays[(date.weekday - 1) % 7];
    final dateText = '$wd, ${_months[date.month - 1]} ${date.day}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bmiColor.withValues(alpha: 0.156), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.078),
              shape: BoxShape.circle,
              border: Border.all(
                  color: bmiColor.withValues(alpha: 0.207), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.bmi.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 18 / 16,
                    fontWeight: FontWeight.w700,
                    color: bmiColor,
                  ),
                ),
                Text(
                  getBMIShortLabel(item.bmi).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: bmiColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(colors, FeatherIcons.maximize2, '${item.height} cm'),
                    _pill(
                      colors,
                      FeatherIcons.database,
                      '${item.weight.toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(dynamic colors, IconData icon, String text) {
    return Container(
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
  }
}
