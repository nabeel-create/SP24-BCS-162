import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_view.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});
  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<Department> _departments = [];
  List<Section> _sections = [];
  int? _expanded;
  bool _loading = true;
  final _deptCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _deptCtrl.dispose(); _sectionCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final depts = await ApiService.instance.getDepartments();
      if (mounted) setState(() { _departments = depts; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadSections(int deptId) async {
    final secs = await ApiService.instance.getSections(departmentId: deptId);
    if (mounted) setState(() => _sections = secs);
  }

  Future<void> _addDept() async {
    final name = _deptCtrl.text.trim();
    if (name.isEmpty) return;
    await ApiService.instance.createDepartment(name: name);
    _deptCtrl.clear();
    HapticFeedback.heavyImpact();
    _load();
  }

  Future<void> _addSection() async {
    if (_expanded == null) return;
    final name = _sectionCtrl.text.trim();
    if (name.isEmpty) return;
    await ApiService.instance.createSection(name: name, departmentId: _expanded!);
    _sectionCtrl.clear();
    HapticFeedback.heavyImpact();
    await _loadSections(_expanded!);
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
              left: 16, right: 16, bottom: 12,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Departments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _deptCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'New department name…',
                        hintStyle: TextStyle(color: AppColors.mutedFg),
                        border: InputBorder.none, isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _addDept(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addDept,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.primary,
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _departments.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.business_outlined, size: 40, color: AppColors.mutedFg),
                        const SizedBox(height: 8),
                        const Text('No departments yet', style: TextStyle(color: AppColors.mutedFg)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _departments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final dept = _departments[i];
                            final isExp = _expanded == dept.id;
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Column(children: [
                                // Dept row
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExp) {
                                        _expanded = null;
                                        _sections = [];
                                      } else {
                                        _expanded = dept.id;
                                        _sections = [];
                                        _sectionCtrl.clear();
                                      }
                                    });
                                    if (!isExp) _loadSections(dept.id);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(children: [
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.business, color: AppColors.primary, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(dept.name,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                      Icon(isExp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          size: 18, color: AppColors.mutedFg),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          HapticFeedback.heavyImpact();
                                          await ApiService.instance.deleteDepartment(dept.id);
                                          if (_expanded == dept.id) setState(() { _expanded = null; _sections = []; });
                                          _load();
                                        },
                                        child: const Icon(Icons.delete_outline, size: 16, color: AppColors.absent),
                                      ),
                                    ]),
                                  ),
                                ),
                                // Expanded sections panel
                                if (isExp)
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: AppColors.border)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      // Existing sections
                                      ..._sections.map((s) => Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppColors.border)),
                                        ),
                                        child: Row(children: [
                                          const Icon(Icons.layers_outlined, size: 14, color: AppColors.mutedFg),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13))),
                                          GestureDetector(
                                            onTap: () async {
                                              await ApiService.instance.deleteSection(s.id);
                                              _loadSections(dept.id);
                                            },
                                            child: const Icon(Icons.close, size: 14, color: AppColors.absent),
                                          ),
                                        ]),
                                      )),
                                      // Add section row
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.border),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: TextField(
                                                controller: _sectionCtrl,
                                                style: const TextStyle(fontSize: 13),
                                                decoration: const InputDecoration(
                                                  hintText: 'Add section…',
                                                  hintStyle: TextStyle(color: AppColors.mutedFg, fontSize: 13),
                                                  border: InputBorder.none, isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                ),
                                                onSubmitted: (_) => _addSection(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _addSection,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ]),
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
