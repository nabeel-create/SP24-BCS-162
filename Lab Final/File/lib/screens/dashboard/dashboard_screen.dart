import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/mini_chart.dart';
import '../../widgets/loading_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  List<TrendPoint>? _trend;
  Map<String, int>? _today;
  List<DeptStat>? _deptStats;
  List<ActivityItem>? _activity;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.instance.getDashboardSummary(),
        ApiService.instance.getAttendanceTrend(),
        ApiService.instance.getTodayAttendance(),
        ApiService.instance.getDepartmentStats(),
        ApiService.instance.getRecentActivity(),
      ]);
      if (mounted) setState(() {
        _summary = results[0] as DashboardSummary;
        _trend = results[1] as List<TrendPoint>;
        _today = results[2] as Map<String, int>;
        _deptStats = results[3] as List<DeptStat>;
        _activity = results[4] as List<ActivityItem>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.card,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Text('Attendance overview', style: TextStyle(fontSize: 13, color: AppColors.mutedFg)),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Expanded(child: LoadingView())
            else if (_error != null)
              Expanded(child: ErrorView(message: 'Failed to load dashboard', onRetry: _load))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_summary != null) ...[
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            StatCard(title: 'Total Students', value: '${_summary!.totalStudents}',
                                icon: Icons.people_outline, iconColor: AppColors.primary, iconBg: AppColors.secondary),
                            StatCard(title: 'Attendance Rate', value: '${_summary!.attendanceRate.toStringAsFixed(1)}%',
                                icon: Icons.trending_up, iconColor: AppColors.present, iconBg: AppColors.presentBg),
                            StatCard(title: 'Total Teachers', value: '${_summary!.totalTeachers}',
                                icon: Icons.menu_book_outlined, iconColor: AppColors.purple, iconBg: AppColors.purpleBg),
                            StatCard(title: 'Departments', value: '${_summary!.totalDepartments}',
                                icon: Icons.business_center_outlined, iconColor: AppColors.amber, iconBg: AppColors.amberBg),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_trend != null) ...[
                        _card(
                          title: 'Attendance Trend (7 Days)',
                          subtitle: 'Present · Absent · Late',
                          child: Column(
                            children: [
                              Row(children: [
                                for (final e in [
                                  (AppColors.present, 'Present'),
                                  (AppColors.absent, 'Absent'),
                                  (AppColors.late, 'Late'),
                                ]) ...[
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: e.$1, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(e.$2, style: const TextStyle(fontSize: 11, color: AppColors.mutedFg)),
                                  const SizedBox(width: 10),
                                ]
                              ]),
                              const SizedBox(height: 10),
                              MiniTrendChart(data: _trend!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_today != null) ...[
                        _card(
                          title: "Today's Overview",
                          child: Column(
                            children: [
                              for (final e in [
                                ('Present', _today!['present']!, AppColors.present, AppColors.presentBg),
                                ('Absent', _today!['absent']!, AppColors.absent, AppColors.absentBg),
                                ('Late', _today!['late']!, AppColors.late, AppColors.lateBg),
                              ])
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: e.$4, borderRadius: BorderRadius.circular(8)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text(e.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: e.$3)),
                                    Text('${e.$2}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: e.$3)),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_deptStats != null && _deptStats!.isNotEmpty) ...[
                        _card(
                          title: 'Department Stats',
                          subtitle: 'Attendance rate by department',
                          child: MiniBarChart(
                            data: _deptStats!.map((d) => (label: d.department, value: d.attendanceRate)).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_activity != null && _activity!.isNotEmpty)
                        _card(
                          title: 'Recent Activity',
                          child: Column(
                            children: _activity!.take(8).toList().asMap().entries.map((e) {
                              final item = e.value;
                              final isLast = e.key == (_activity!.length - 1 > 7 ? 7 : _activity!.length - 1);
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.secondary,
                                        child: Text(
                                          item.studentName.isNotEmpty ? item.studentName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(item.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        Text(item.rollNo, style: const TextStyle(fontSize: 11, color: AppColors.mutedFg)),
                                      ])),
                                      StatusBadge(status: item.status),
                                      const SizedBox(width: 8),
                                      Text(item.time.length > 10 ? item.time.substring(0, 10) : item.time,
                                          style: const TextStyle(fontSize: 11, color: AppColors.mutedFg)),
                                    ]),
                                  ),
                                  if (!isLast) const Divider(height: 1),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, String? subtitle, required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedFg)),
          ],
          const SizedBox(height: 12),
          child,
        ]),
      );
}
