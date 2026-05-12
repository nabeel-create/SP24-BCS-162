import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../state/submission_store.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar.dart';
import 'dashboard_page.dart';
import 'form_page.dart';
import 'stats_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final SubmissionStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection section = AppSection.dashboard;
  Submission? editing;

  void openForm([Submission? submission]) {
    setState(() {
      editing = submission;
      section = AppSection.form;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (section) {
      case AppSection.form:
        page = FormPage(
          store: widget.store,
          editing: editing,
          onDone: () => setState(() {
            editing = null;
            section = AppSection.dashboard;
          }),
        );
        break;
      case AppSection.stats:
        page = StatsPage(store: widget.store);
        break;
      case AppSection.dashboard:
        page = DashboardPage(
          store: widget.store,
          onNew: () => openForm(),
          onEdit: openForm,
          onStats: () => setState(() => section = AppSection.stats),
        );
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 860) {
            return Column(
              children: [
                _MobileNav(
                  active: section,
                  onSelect: (next) => setState(() {
                    editing = null;
                    section = next;
                  }),
                ),
                Expanded(child: page),
              ],
            );
          }
          return Row(
            children: [
              Sidebar(
                active: section,
                totalCount: widget.store.submissions.length,
                onSelect: (next) => setState(() {
                  editing = null;
                  section = next;
                }),
              ),
              Expanded(child: page),
            ],
          );
        },
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.active, required this.onSelect});

  final AppSection active;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _button(AppSection.dashboard, Icons.grid_view_rounded, 'Dashboard'),
          _button(AppSection.form, Icons.add_circle_outline, 'New Entry'),
          _button(AppSection.stats, Icons.bar_chart_rounded, 'Analytics'),
        ],
      ),
    );
  }

  Widget _button(AppSection section, IconData icon, String label) {
    final selected = section == active;
    return Expanded(
      child: TextButton.icon(
        onPressed: () => onSelect(section),
        icon: Icon(
          icon,
          size: 17,
          color: selected ? Colors.white : AppColors.sidebarText,
        ),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : AppColors.sidebarText,
          backgroundColor: selected ? AppColors.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
