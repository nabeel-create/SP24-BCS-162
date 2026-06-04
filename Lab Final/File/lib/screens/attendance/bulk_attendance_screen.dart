import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_view.dart';

class BulkAttendanceScreen extends StatefulWidget {
  const BulkAttendanceScreen({super.key});
  @override
  State<BulkAttendanceScreen> createState() => _BulkAttendanceScreenState();
}

class _BulkAttendanceScreenState extends State<BulkAttendanceScreen> {
  List<Section> _sections = [];
  List<Subject> _subjects = [];
  List<Student> _students = [];
  int? _sectionId;
  int? _subjectId;
  Map<int, String> _statuses = {};
  bool _initing = true;
  bool _loadingStudents = false;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final res = await Future.wait([ApiService.instance.getSections(), ApiService.instance.getSubjects()]);
    if (mounted) setState(() {
      _sections = res[0] as List<Section>;
      _subjects = res[1] as List<Subject>;
      _initing = false;
    });
  }

  Future<void> _loadStudents(int sectionId) async {
    setState(() { _loadingStudents = true; _students = []; _statuses = {}; });
    final students = await ApiService.instance.getStudents(sectionId: sectionId);
    if (mounted) setState(() {
      _students = students;
      _statuses = {};
      _loadingStudents = false;
    });
  }

  void _setAll(String status) {
    HapticFeedback.selectionClick();
    setState(() { for (final s in _students) _statuses[s.id] = status; });
  }

  Future<void> _submit() async {
    if (_sectionId == null || _subjectId == null || _statuses.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.instance.markBulkAttendance(
        date: DateTime.now().toIso8601String().split('T')[0],
        sectionId: _sectionId!,
        subjectId: _subjectId!,
        records: _statuses.entries.map((e) => {'studentId': e.key, 'status': e.value}).toList(),
      );
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _filterChip(String label, int? value, int? current) {
    final selected = current == value;
    return GestureDetector(
      onTap: () {
        if (label == 'Section chips') return;
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.mutedFg,
          fontSize: 12, fontWeight: FontWeight.w500,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Bulk Attendance'),
          backgroundColor: AppColors.card,
          bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline, size: 52, color: AppColors.present),
            const SizedBox(height: 12),
            const Text('Attendance Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bulk Attendance'),
        backgroundColor: AppColors.card,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: _initing
          ? const LoadingView()
          : Stack(
              children: [
                Column(
                  children: [
                    // Section + Subject chip filters
                    Container(
                      color: AppColors.card,
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('SECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.mutedFg, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: _sections.map((s) {
                            final selected = _sectionId == s.id;
                            return GestureDetector(
                              onTap: () {
                                setState(() { _sectionId = s.id; });
                                _loadStudents(s.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : AppColors.muted,
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
                        const SizedBox(height: 10),
                        const Text('SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.mutedFg, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: _subjects.map((s) {
                            final selected = _subjectId == s.id;
                            return GestureDetector(
                              onTap: () => setState(() => _subjectId = s.id),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : AppColors.muted,
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
                      ]),
                    ),
                    // Bulk action buttons
                    if (_sectionId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                        child: Row(children: [
                          for (final st in ['present', 'absent', 'late'])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _setAll(st),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: st == 'present' ? AppColors.presentBg
                                        : st == 'absent' ? AppColors.absentBg : AppColors.lateBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'All ${st[0].toUpperCase()}${st.substring(1)}',
                                    style: TextStyle(
                                      color: st == 'present' ? AppColors.present
                                          : st == 'absent' ? AppColors.absent : AppColors.late,
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    // Student list
                    Expanded(
                      child: _loadingStudents
                          ? const LoadingView()
                          : _students.isEmpty
                              ? Center(child: Text(
                                  _sectionId == null ? 'Select a section to begin' : 'No students in this section',
                                  style: const TextStyle(color: AppColors.mutedFg, fontSize: 14),
                                ))
                              : ListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 12, right: 12, top: 8,
                                    bottom: (_sectionId != null && _subjectId != null && _statuses.isNotEmpty) ? 90 : 20,
                                  ),
                                  itemCount: _students.length,
                                  itemBuilder: (_, i) {
                                    final s = _students[i];
                                    final cur = _statuses[s.id];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 38, height: 38,
                                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                          alignment: Alignment.center,
                                          child: Text(
                                            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text(s.rollNo, style: const TextStyle(fontSize: 11, color: AppColors.mutedFg)),
                                        ])),
                                        Row(children: [
                                          for (final st in ['present', 'absent', 'late'])
                                            GestureDetector(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                setState(() => _statuses[s.id] = st);
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                width: 26, height: 26,
                                                decoration: BoxDecoration(
                                                  color: cur == st
                                                      ? (st == 'present' ? AppColors.present
                                                          : st == 'absent' ? AppColors.absent : AppColors.late)
                                                      : AppColors.muted,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  st[0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: cur == st ? Colors.white : AppColors.mutedFg,
                                                    fontSize: 10, fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ]),
                                      ]),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
                // Submit bar
                if (_sectionId != null && _subjectId != null && _statuses.isNotEmpty)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 16, right: 16, top: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_statuses.length} / ${_students.length} marked',
                            style: const TextStyle(fontSize: 13, color: AppColors.mutedFg),
                          ),
                          GestureDetector(
                            onTap: _submitting ? null : _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                              child: _submitting
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Submit Attendance', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
