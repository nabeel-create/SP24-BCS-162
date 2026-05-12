import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../state/submission_store.dart';
import '../theme/app_colors.dart';
import '../widgets/gender_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.store});

  final SubmissionStore store;

  @override
  Widget build(BuildContext context) {
    final stats = _Analytics.from(store.submissions);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Submission insights and trends',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: store.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _AnalyticCard(
                            title: 'Total',
                            value: stats.total,
                            sub: 'all time',
                            icon: Icons.groups_rounded,
                            bg: const Color(0xFFEDE9FE),
                            fg: AppColors.primary,
                          ),
                          _AnalyticCard(
                            title: 'Today',
                            value: stats.today,
                            sub: 'new today',
                            icon: Icons.calendar_today_rounded,
                            bg: const Color(0xFFD1FAE5),
                            fg: AppColors.success,
                          ),
                          _AnalyticCard(
                            title: 'This Week',
                            value: stats.thisWeek,
                            sub: 'last 7 days',
                            icon: Icons.trending_up_rounded,
                            bg: const Color(0xFFDBEAFE),
                            fg: AppColors.info,
                          ),
                          _AnalyticCard(
                            title: 'Male',
                            value: stats.male,
                            sub: '${stats.percent(stats.male)}%',
                            icon: Icons.person_rounded,
                            bg: const Color(0xFFDBEAFE),
                            fg: AppColors.info,
                          ),
                          _AnalyticCard(
                            title: 'Female',
                            value: stats.female,
                            sub: '${stats.percent(stats.female)}%',
                            icon: Icons.person_rounded,
                            bg: const Color(0xFFFCE7F3),
                            fg: const Color(0xFFBE185D),
                          ),
                          _AnalyticCard(
                            title: 'Other',
                            value: stats.other,
                            sub: '${stats.percent(stats.other)}%',
                            icon: Icons.person_outline_rounded,
                            bg: const Color(0xFFEDE9FE),
                            fg: const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 760) {
                            return Column(
                              children: [
                                GenderChart(
                                  male: stats.male,
                                  female: stats.female,
                                  other: stats.other,
                                  total: stats.total,
                                ),
                                const SizedBox(height: 14),
                                _TrendCard(entries: stats.dailyEntries),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GenderChart(
                                  male: stats.male,
                                  female: stats.female,
                                  other: stats.other,
                                  total: stats.total,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _TrendCard(entries: stats.dailyEntries),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _Breakdown(stats: stats),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  const _AnalyticCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String title;
  final int value;
  final String sub;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: bg),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: fg,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Color(0xFF9F8EC7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<int>(
      1,
      (max, item) => item.value > max ? item.value : max,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Trend',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Last 7 active days',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final entry in entries)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: entry.value / maxValue,
                                  widthFactor: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.purpleGradient(),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
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

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.stats});

  final _Analytics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Entries Overview',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${stats.total} total record${stats.total == 1 ? '' : 's'} in database',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _BreakdownItem(
                label: 'Male',
                count: stats.male,
                percent: stats.percent(stats.male),
                color: AppColors.info,
                bg: const Color(0xFFDBEAFE),
              ),
              _BreakdownItem(
                label: 'Female',
                count: stats.female,
                percent: stats.percent(stats.female),
                color: const Color(0xFFBE185D),
                bg: const Color(0xFFFCE7F3),
              ),
              _BreakdownItem(
                label: 'Other',
                count: stats.other,
                percent: stats.percent(stats.other),
                color: const Color(0xFF7C3AED),
                bg: const Color(0xFFEDE9FE),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
    required this.bg,
  });

  final String label;
  final int count;
  final int percent;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Analytics {
  const _Analytics({
    required this.total,
    required this.male,
    required this.female,
    required this.other,
    required this.today,
    required this.thisWeek,
    required this.dailyEntries,
  });

  final int total;
  final int male;
  final int female;
  final int other;
  final int today;
  final int thisWeek;
  final List<MapEntry<String, int>> dailyEntries;

  int percent(int value) => total == 0 ? 0 : (value / total * 100).round();

  factory _Analytics.from(List<Submission> submissions) {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final byDate = <String, int>{};
    for (final item in submissions) {
      final created = item.createdAt?.toLocal();
      if (created == null) continue;
      final key = '${_month(created.month)} ${created.day}';
      byDate[key] = (byDate[key] ?? 0) + 1;
    }
    return _Analytics(
      total: submissions.length,
      male: submissions.where((item) => item.gender == Gender.male).length,
      female: submissions.where((item) => item.gender == Gender.female).length,
      other: submissions.where((item) => item.gender == Gender.other).length,
      today: submissions
          .where(
            (item) =>
                item.createdAt != null &&
                _dayKey(item.createdAt!.toLocal()) == todayKey,
          )
          .length,
      thisWeek: submissions
          .where(
            (item) =>
                item.createdAt != null &&
                now.difference(item.createdAt!.toLocal()).inDays <= 7,
          )
          .length,
      dailyEntries: byDate.entries.toList().take(7).toList(),
    );
  }

  static String _dayKey(DateTime date) =>
      date.toIso8601String().substring(0, 10);
  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
