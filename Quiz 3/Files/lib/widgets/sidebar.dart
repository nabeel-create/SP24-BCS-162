import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppSection { dashboard, form, stats }

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.active,
    required this.totalCount,
    required this.onSelect,
  });

  final AppSection active;
  final int totalCount;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.purpleGradient()),
            child: const Row(
              children: [
                _LogoIcon(),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FormBase',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Quiz 3 - CSC303',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        color: AppColors.sidebarText,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _NavItem(
                    section: AppSection.dashboard,
                    active: active,
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    onSelect: onSelect,
                  ),
                  _NavItem(
                    section: AppSection.form,
                    active: active,
                    icon: Icons.add_circle_outline,
                    label: 'New Entry',
                    onSelect: onSelect,
                  ),
                  _NavItem(
                    section: AppSection.stats,
                    active: active,
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    onSelect: onSelect,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.sidebarBorder)),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sidebarBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storage_rounded,
                    color: AppColors.sidebarText,
                    size: 14,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '$totalCount records in Supabase',
                      style: const TextStyle(
                        color: AppColors.sidebarText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.description_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.active,
    required this.icon,
    required this.label,
    required this.onSelect,
  });

  final AppSection section;
  final AppSection active;
  final IconData icon;
  final String label;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = section == active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onSelect(section),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.sidebarText,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.sidebarText,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
