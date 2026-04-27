import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class _Tab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _Tab(this.label, this.icon, this.builder);
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;

  static final _tabs = <_Tab>[
    _Tab('Calculator', FeatherIcons.activity, (_) => const HomeScreen()),
    _Tab('History', FeatherIcons.clock, (_) => const HistoryScreen()),
    _Tab('Profile', FeatherIcons.user, (_) => const ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.builder(context)).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            top: BorderSide(color: colors.border, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(4, 8, 4, bottom == 0 ? 8 : bottom),
        child: Row(
          children: [
            for (int i = 0; i < _tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_index == i) return;
                    HapticFeedback.lightImpact();
                    setState(() => _index = i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabs[i].icon,
                          size: 20,
                          color: _index == i
                              ? colors.primary
                              : colors.mutedForeground,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tabs[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: _index == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _index == i
                                ? colors.primary
                                : colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
