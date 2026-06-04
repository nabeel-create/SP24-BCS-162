import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_view.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<Teacher> _teachers = [];
  List<Department> _departments = [];
  bool _loading = true;
  bool _showModal = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  int? _deptId;
  String _error = '';
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiService.instance.getTeachers(),
        ApiService.instance.getDepartments(),
      ]);
      if (mounted) setState(() {
        _teachers = res[0] as List<Teacher>;
        _departments = res[1] as List<Department>;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _error = 'Name is required'); return; }
    setState(() => _saving = true);
    try {
      await ApiService.instance.createTeacher(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        departmentId: _deptId,
      );
      HapticFeedback.heavyImpact();
      _nameCtrl.clear(); _emailCtrl.clear();
      setState(() { _deptId = null; _showModal = false; });
      _load();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(int id) async {
    HapticFeedback.mediumImpact();
    await ApiService.instance.deleteTeacher(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teachers'),
        backgroundColor: AppColors.card,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: () => setState(() => _showModal = true),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const LoadingView()
              : _teachers.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.book_outlined, size: 40, color: AppColors.mutedFg),
                      const SizedBox(height: 8),
                      const Text('No teachers yet', style: TextStyle(color: AppColors.mutedFg)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _showModal = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Add Teacher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _teachers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final t = _teachers[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: const BoxDecoration(color: AppColors.purpleBg, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(
                                  t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.purple),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(
                                  t.email ?? t.departmentName ?? '—',
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
                                ),
                              ])),
                              GestureDetector(
                                onTap: () => _remove(t.id),
                                child: const Icon(Icons.delete_outline, size: 18, color: AppColors.absent),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
          // Bottom sheet modal matching Expo
          if (_showModal)
            GestureDetector(
              onTap: () => setState(() { _showModal = false; _nameCtrl.clear(); _emailCtrl.clear(); _deptId = null; _error = ''; }),
              child: Container(color: Colors.black54),
            ),
          if (_showModal)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add Teacher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: () => setState(() { _showModal = false; _nameCtrl.clear(); _emailCtrl.clear(); _deptId = null; _error = ''; }),
                          child: const Icon(Icons.close, color: AppColors.mutedFg),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _inputField('Full Name *', _nameCtrl),
                      const SizedBox(height: 12),
                      _inputField('Email', _emailCtrl, type: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      const Text('DEPARTMENT (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedFg, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _departments.map((d) {
                          final sel = _deptId == d.id;
                          return GestureDetector(
                            onTap: () => setState(() => _deptId = sel ? null : d.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.muted,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(d.name, style: TextStyle(
                                color: sel ? Colors.white : AppColors.foreground,
                                fontSize: 12, fontWeight: FontWeight.w500,
                              )),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_error, style: const TextStyle(color: AppColors.absent, fontSize: 13)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _saving ? null : _submit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Add Teacher', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, {TextInputType? type}) => Container(
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
  );
}
