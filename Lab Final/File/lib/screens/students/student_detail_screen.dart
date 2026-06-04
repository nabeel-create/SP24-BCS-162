import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_view.dart';
import 'face_register_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});
  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Student? _student;
  List<AttendanceRecord> _attendance = [];
  double? _percentage;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiService.instance.getStudent(widget.studentId),
        ApiService.instance.getAttendance(studentId: widget.studentId),
        ApiService.instance.getStudentAttendancePercentage(widget.studentId),
      ]);
      if (mounted) setState(() {
        _student = res[0] as Student;
        _attendance = res[1] as List<AttendanceRecord>;
        _percentage = res[2] as double;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final pct = _percentage ?? 0;
    final pctColor = pct >= 75 ? AppColors.present : pct >= 60 ? AppColors.late : AppColors.absent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: AppColors.card,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (_student != null)
            IconButton(
              icon: const Icon(Icons.face_outlined, color: AppColors.primary),
              tooltip: 'Register Face',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => FaceRegisterScreen(student: _student!)))
                  .then((_) => _load()),
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _student == null
              ? const ErrorView(message: 'Student not found')
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: 16, right: 16, top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    children: [
                      // Profile card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          // Avatar
                          Container(
                            width: 72, height: 72,
                            decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              _student!.name.isNotEmpty ? _student!.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_student!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_student!.rollNo, style: const TextStyle(fontSize: 14, color: AppColors.mutedFg)),
                          const SizedBox(height: 16),
                          // Meta row
                          Row(children: [
                            for (final m in [
                              ('Section', _student!.sectionName ?? '-'),
                              ('Department', _student!.departmentName ?? '-'),
                              ('Email', _student!.email ?? '-'),
                            ])
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.muted,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m.$1, style: const TextStyle(fontSize: 10, color: AppColors.mutedFg)),
                                    const SizedBox(height: 2),
                                    Text(m.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ]),
                                ),
                              ),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // Attendance percentage card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Text('${pct.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: pctColor)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (pct / 100).clamp(0.0, 1.0),
                                  backgroundColor: AppColors.muted,
                                  color: pctColor,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pct >= 75 ? 'Good standing' : 'Below threshold (75%)',
                                style: TextStyle(fontSize: 12, color: pctColor),
                              ),
                            ])),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // History card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Attendance History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (_attendance.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No records yet', style: TextStyle(color: AppColors.mutedFg)),
                            )
                          else
                            ...(_attendance.take(20).toList().asMap().entries.map((e) {
                              final r = e.value;
                              final isLast = e.key >= (_attendance.length - 1).clamp(0, 19);
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                                ),
                                child: Row(children: [
                                  Expanded(child: Text(r.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                  if (r.subjectName != null)
                                    Expanded(child: Text(r.subjectName!, style: const TextStyle(fontSize: 12, color: AppColors.mutedFg))),
                                  StatusBadge(status: r.status),
                                ]),
                              );
                            })),
                        ]),
                      ),
                    ],
                  ),
                ),
    );
  }
}
