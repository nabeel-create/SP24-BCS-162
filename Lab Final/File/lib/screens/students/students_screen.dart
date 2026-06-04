import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_view.dart';
import 'student_detail_screen.dart';
import 'add_student_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> _students = [];
  List<Department> _departments = [];
  List<Section> _sections = [];
  bool _loading = true;
  String _search = '';
  int? _deptId;
  int? _sectionId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final futures = <Future>[
        ApiService.instance.getStudents(
          search: _search.isEmpty ? null : _search,
          departmentId: _deptId,
          sectionId: _sectionId,
        ),
        ApiService.instance.getDepartments(),
        if (_deptId != null) ApiService.instance.getSections(departmentId: _deptId),
      ];
      final results = await Future.wait(futures);
      if (mounted) setState(() {
        _students = results[0] as List<Student>;
        _departments = results[1] as List<Department>;
        if (_deptId != null && results.length > 2) {
          _sections = results[2] as List<Section>;
        } else {
          _sections = [];
        }
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Widget _chip(String label, int? value, int? current, void Function(int?) onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
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
                  const Text('Students', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddStudentScreen()))
                        .then((_) => _load()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.search, size: 16, color: AppColors.mutedFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search students…',
                        hintStyle: TextStyle(color: AppColors.mutedFg, fontSize: 14),
                        border: InputBorder.none, isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (v) { _search = v; _load(); },
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchCtrl.clear(); _search = ''; _load(); },
                      child: const Icon(Icons.close, size: 16, color: AppColors.mutedFg),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              if (_departments.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _chip('All Depts', null, _deptId, (v) {
                      setState(() { _deptId = null; _sectionId = null; _sections = []; });
                      _load();
                    }),
                    ..._departments.map((d) => _chip(d.name, d.id, _deptId, (v) {
                      setState(() { _deptId = d.id; _sectionId = null; _sections = []; });
                      _load();
                    })),
                  ]),
                ),
              if (_deptId != null && _sections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _chip('All Sections', null, _sectionId, (v) {
                        setState(() => _sectionId = null);
                        _load();
                      }),
                      ..._sections.map((s) => _chip(s.name, s.id, _sectionId, (v) {
                        setState(() => _sectionId = s.id);
                        _load();
                      })),
                    ]),
                  ),
                ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _students.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.people_outline, size: 40, color: AppColors.mutedFg),
                        const SizedBox(height: 8),
                        const Text('No students found', style: TextStyle(fontSize: 14, color: AppColors.mutedFg)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = _students[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id)))
                                  .then((_) => _load()),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.rollNo}${s.sectionName != null ? ' · ${s.sectionName}' : ''}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
                                    ),
                                  ])),
                                  Row(children: [
                                    if (s.hasFace)
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.presentBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.camera_alt, size: 12, color: AppColors.present),
                                      ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedFg),
                                  ]),
                                ]),
                              ),
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
