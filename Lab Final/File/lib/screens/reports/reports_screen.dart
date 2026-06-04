import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_view.dart';

const _thresholds = [60, 65, 70, 75, 80, 85];

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<DefaulterStudent> _defaulters = [];
  List<Department> _departments = [];
  double _threshold = 75;
  int? _deptId;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiService.instance.getDefaulters(threshold: _threshold, departmentId: _deptId),
        ApiService.instance.getDepartments(),
      ]);
      if (mounted) setState(() {
        _defaulters = res[0] as List<DefaulterStudent>;
        _departments = res[1] as List<Department>;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Widget _chip(String label, dynamic value, dynamic current) {
    final selected = current == value;
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? (label.endsWith('%') ? AppColors.absent : AppColors.primary)
              : AppColors.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.mutedFg,
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Defaulters Report'),
        backgroundColor: AppColors.card,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('THRESHOLD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.mutedFg, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                children: _thresholds.map((t) {
                  final selected = _threshold == t.toDouble();
                  return GestureDetector(
                    onTap: () { setState(() => _threshold = t.toDouble()); _load(); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.absent : AppColors.muted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('$t%', style: TextStyle(
                        color: selected ? Colors.white : AppColors.mutedFg,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.mutedFg, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  GestureDetector(
                    onTap: () { setState(() => _deptId = null); _load(); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _deptId == null ? AppColors.primary : AppColors.muted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('All', style: TextStyle(
                        color: _deptId == null ? Colors.white : AppColors.mutedFg,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                  ..._departments.map((d) {
                    final selected = _deptId == d.id;
                    return GestureDetector(
                      onTap: () { setState(() => _deptId = d.id); _load(); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.muted,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(d.name, style: TextStyle(
                          color: selected ? Colors.white : AppColors.mutedFg,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                      ),
                    );
                  }),
                ],
              ),
            ]),
          ),
          if (!_loading && _defaulters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.absentBg,
              child: Row(children: [
                const Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.absent),
                const SizedBox(width: 8),
                Text(
                  '${_defaulters.length} student${_defaulters.length != 1 ? 's' : ''} below ${_threshold.round()}% attendance',
                  style: const TextStyle(fontSize: 13, color: AppColors.absent, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _defaulters.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle_outline, size: 44, color: AppColors.present),
                        const SizedBox(height: 10),
                        const Text('All Good!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('No students below ${_threshold.round()}%',
                            style: const TextStyle(fontSize: 14, color: AppColors.mutedFg)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _defaulters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = _defaulters[i];
                            final pct = s.percentage;
                            final barColor = pct >= 60 ? AppColors.late : AppColors.absent;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: AppColors.absentBg, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.absent),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text(
                                      '${s.rollNo}${s.departmentName != null ? ' · ${s.departmentName}' : ''}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
                                    ),
                                  ])),
                                  Text('${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: barColor)),
                                ]),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: (pct / 100).clamp(0.0, 1.0),
                                    backgroundColor: AppColors.muted,
                                    color: barColor,
                                    minHeight: 6,
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
