import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../state/submission_store.dart';
import '../theme/app_colors.dart';
import '../widgets/gender_chart.dart';
import '../widgets/gradient_button.dart';
import '../widgets/search_filter.dart';
import '../widgets/stat_card.dart';
import '../widgets/submission_table.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.store,
    required this.onNew,
    required this.onEdit,
    required this.onStats,
  });

  final SubmissionStore store;
  final VoidCallback onNew;
  final ValueChanged<Submission> onEdit;
  final VoidCallback onStats;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final queryController = TextEditingController();
  GenderFilter genderFilter = GenderFilter.all;
  SortKey sort = SortKey.newest;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissions = widget.store.submissions;
    final filtered = _filtered(submissions);
    final stats = _Stats.from(submissions);

    return Column(
      children: [
        _TopBar(
          title: 'Dashboard',
          subtitle: 'Manage all submission records',
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: widget.store.refetch,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
            ),
            GradientButton(
              label: 'New Entry',
              icon: Icons.add_rounded,
              onPressed: widget.onNew,
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.store.config.isReady)
                  const _ErrorBox(
                    message:
                        'Paste Supabase URL and anon key in lib/services/supabase_credentials.dart',
                    onRetry: null,
                  )
                else if (widget.store.loading)
                  const _Loading()
                else if (widget.store.error == 'TABLE_NOT_FOUND')
                  _SetupCard(onRetry: widget.store.refetch)
                else if (widget.store.error != null)
                  _ErrorBox(
                    message: widget.store.error!,
                    onRetry: widget.store.refetch,
                  )
                else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final cardWidth = width < 900 ? width : (width - 42) / 4;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Total',
                              value: submissions.length,
                              subtitle: 'all time',
                              icon: Icons.groups_rounded,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Today',
                              value: stats.today,
                              subtitle: 'new entries',
                              icon: Icons.add_circle_outline,
                              gradient: const [
                                Color(0xFF059669),
                                Color(0xFF10B981),
                              ],
                              accent: AppColors.success,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Male',
                              value: stats.male,
                              subtitle: '${stats.percent(stats.male)}%',
                              icon: Icons.person_rounded,
                              gradient: const [
                                Color(0xFF1D4ED8),
                                Color(0xFF3B82F6),
                              ],
                              accent: AppColors.info,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Female',
                              value: stats.female,
                              subtitle: '${stats.percent(stats.female)}%',
                              icon: Icons.person_rounded,
                              gradient: const [
                                Color(0xFF9D174D),
                                Color(0xFFEC4899),
                              ],
                              accent: const Color(0xFF9D174D),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GenderChart(
                    male: stats.male,
                    female: stats.female,
                    other: stats.other,
                    total: submissions.length,
                  ),
                  const SizedBox(height: 16),
                  SearchFilter(
                    queryController: queryController,
                    onQueryChanged: (_) => setState(() {}),
                    genderFilter: genderFilter,
                    onGenderChanged: (value) =>
                        setState(() => genderFilter = value),
                    sort: sort,
                    onSortChanged: (value) => setState(() => sort = value),
                    resultCount: filtered.length,
                    totalCount: submissions.length,
                  ),
                  const SizedBox(height: 16),
                  SubmissionTable(
                    data: filtered,
                    deletingId: widget.store.deletingId,
                    onEdit: widget.onEdit,
                    onDelete: (item) => _confirmDelete(context, item),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Submission> _filtered(List<Submission> source) {
    final q = queryController.text.toLowerCase().trim();
    final filtered = source.where((item) {
      final matchesSearch =
          q.isEmpty ||
          item.fullName.toLowerCase().contains(q) ||
          item.email.toLowerCase().contains(q) ||
          item.phoneNumber.contains(q) ||
          item.address.toLowerCase().contains(q);
      final matchesGender =
          genderFilter == GenderFilter.all ||
          item.gender.label == genderFilter.label;
      return matchesSearch && matchesGender;
    }).toList();

    switch (sort) {
      case SortKey.oldest:
        filtered.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
      case SortKey.nameAsc:
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
      case SortKey.nameDesc:
        filtered.sort((a, b) => b.fullName.compareTo(a.fullName));
      case SortKey.newest:
        filtered.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
    }
    return filtered;
  }

  void _confirmDelete(BuildContext context, Submission item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Submission'),
        content: Text("Remove ${item.fullName}'s record permanently?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.store.deleteEntry(item.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _Stats {
  const _Stats(this.male, this.female, this.other, this.today);

  final int male;
  final int female;
  final int other;
  final int today;

  int get total => male + female + other;
  int percent(int value) => total == 0 ? 0 : (value / total * 100).round();

  factory _Stats.from(List<Submission> submissions) {
    final todayString = DateTime.now().toLocal().toIso8601String().substring(
      0,
      10,
    );
    return _Stats(
      submissions.where((item) => item.gender == Gender.male).length,
      submissions.where((item) => item.gender == Gender.female).length,
      submissions.where((item) => item.gender == Gender.other).length,
      submissions
          .where(
            (item) =>
                item.createdAt?.toLocal().toIso8601String().substring(0, 10) ==
                todayString,
          )
          .length,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Connecting to Supabase...',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const sql = '''CREATE TABLE submissions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name text NOT NULL,
  email text NOT NULL,
  phone_number text NOT NULL,
  address text NOT NULL,
  gender text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all"
  ON submissions FOR ALL
  USING (true) WITH CHECK (true);''';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: const Color(0x66F59E0B)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Database Setup Required',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0A1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SelectableText(
              sql,
              style: TextStyle(color: Color(0xFFA78BFA), height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Retry After Running SQL',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
