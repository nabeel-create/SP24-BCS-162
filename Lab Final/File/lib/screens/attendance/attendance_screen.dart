import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_view.dart';
import 'bulk_attendance_screen.dart';
import 'camera_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _records = [];
  List<Section> _sections = [];
  bool _loading = true;
  final String _date = DateTime.now().toIso8601String().split('T')[0];
  int? _sectionId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiService.instance.getAttendance(date: _date, sectionId: _sectionId),
        ApiService.instance.getSections(),
      ]);
      if (mounted) setState(() {
        _records = res[0] as List<AttendanceRecord>;
        _sections = res[1] as List<Section>;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.status == 'present').length;
    final absentCount = _records.where((r) => r.status == 'absent').length;
    final lateCount = _records.where((r) => r.status == 'late').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16, bottom: 10,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(_date, style: const TextStyle(fontSize: 12, color: AppColors.mutedFg)),
                  ]),
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BulkAttendanceScreen())).then((_) => _load()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Bulk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CameraAttendanceScreen())).then((_) => _load()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              // Section filter chips
              if (_sections.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _sections.map((s) {
                    final selected = _sectionId == s.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _sectionId = selected ? null : s.id);
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(s.name, style: TextStyle(
                          color: selected ? Colors.white : AppColors.mutedFg,
                          fontSize: 12, fontWeight: FontWeight.w500,
                        )),
                      ),
                    );
                  }).toList()),
                ),
              const SizedBox(height: 8),
              // Stats pills
              Row(children: [
                for (final e in [
                  ('Present', presentCount, AppColors.present, AppColors.presentBg),
                  ('Absent', absentCount, AppColors.absent, AppColors.absentBg),
                  ('Late', lateCount, AppColors.late, AppColors.lateBg),
                ])
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: e.$4, borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${e.$2}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: e.$3)),
                        Text(e.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: e.$3)),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _records.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_box_outline_blank, size: 40, color: AppColors.mutedFg),
                        const SizedBox(height: 8),
                        const Text('No attendance records for today', style: TextStyle(fontSize: 14, color: AppColors.mutedFg)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const BulkAttendanceScreen())).then((_) => _load()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (r.studentName?.isNotEmpty ?? false) ? r.studentName![0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r.studentName ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text(
                                    '${r.subjectName ?? ''} · ${r.date}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
                                  ),
                                ])),
                                StatusBadge(status: r.status),
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
