import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});
  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  List<Department> _departments = [];
  List<Section> _sections = [];
  int? _deptId;
  int? _sectionId;
  bool _loading = false;
  bool _initing = true;
  String _error = '';

  @override
  void initState() { super.initState(); _init(); }

  @override
  void dispose() { _nameCtrl.dispose(); _rollCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    final depts = await ApiService.instance.getDepartments();
    if (mounted) setState(() { _departments = depts; _initing = false; });
  }

  Future<void> _onDeptTap(int id) async {
    setState(() { _deptId = id; _sectionId = null; _sections = []; });
    final secs = await ApiService.instance.getSections(departmentId: id);
    if (mounted) setState(() => _sections = secs);
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    final name = _nameCtrl.text.trim();
    final roll = _rollCtrl.text.trim();
    if (name.isEmpty || roll.isEmpty) { setState(() => _error = 'Name and Roll No are required'); return; }
    if (_sectionId == null) { setState(() => _error = 'Please select a section'); return; }
    setState(() => _loading = true);
    try {
      await ApiService.instance.createStudent(
        name: name, rollNo: roll,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        sectionId: _sectionId!,
        departmentId: _deptId,
        semester: 1,
      );
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _chip(String label, int? value, int? current, void Function(int?) onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.foreground,
          fontSize: 12, fontWeight: FontWeight.w500,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Student'),
        backgroundColor: AppColors.card,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: _initing
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _field('FULL NAME *', _nameCtrl, hint: 'e.g. Ahmed Khan'),
                  const SizedBox(height: 14),
                  _field('ROLL NUMBER *', _rollCtrl, hint: 'e.g. CS-21-001'),
                  const SizedBox(height: 14),
                  _field('EMAIL', _emailCtrl, hint: 'student@university.edu', type: TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  const Text('DEPARTMENT *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.mutedFg, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    children: _departments.map((d) => _chip(d.name, d.id, _deptId, (_) => _onDeptTap(d.id))).toList(),
                  ),

                  if (_deptId != null && _sections.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text('SECTION *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppColors.mutedFg, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      children: _sections.map((s) => _chip(s.name, s.id, _sectionId, (v) {
                        setState(() => _sectionId = v);
                      })).toList(),
                    ),
                  ],

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_error, style: const TextStyle(color: AppColors.absent, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _loading ? null : _submit,
                      child: Opacity(
                        opacity: _loading ? 0.7 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                          child: _loading
                              ? const Center(child: SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Register Student', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedFg, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.mutedFg),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ],
  );
}
