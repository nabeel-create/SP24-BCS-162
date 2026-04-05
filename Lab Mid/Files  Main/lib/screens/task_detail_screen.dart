import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/sound_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isEditing = false;
  final _subtaskController = TextEditingController();

  late final _titleCtrl = TextEditingController();
  late final _descCtrl = TextEditingController();
  late Category _editCategory;
  late Priority _editPriority;
  late DateTime _editEndDate;

  static const _primary = Color(0xFF6C63FF);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);

  static const _categoryData = {
    Category.work: _CatD(color: Color(0xFF6C63FF), label: 'Work'),
    Category.study: _CatD(color: Color(0xFF10B981), label: 'Study'),
    Category.personal: _CatD(color: Color(0xFFF59E0B), label: 'Personal'),
    Category.health: _CatD(color: Color(0xFFEF4444), label: 'Health'),
    Category.shopping: _CatD(color: Color(0xFF3B82F6), label: 'Shopping'),
    Category.other: _CatD(color: Color(0xFF8B5CF6), label: 'Other'),
  };

  static const _priorities = [
    (Priority.low, 'Low', Color(0xFF10B981)),
    (Priority.medium, 'Medium', Color(0xFFF59E0B)),
    (Priority.high, 'High', Color(0xFFEF4444)),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _initEdit(Task task) {
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description;
    _editCategory = task.category;
    _editPriority = task.priority;
    _editEndDate = task.endDate;
  }

  Future<void> _saveEdit(Task task, TaskProvider provider) async {
    final updated = task.copyWith(
      title: _titleCtrl.text.trim().isEmpty ? task.title : _titleCtrl.text.trim(),
      description: _descCtrl.text,
      category: _editCategory,
      priority: _editPriority,
      endDate: _editEndDate,
    );
    await provider.updateTask(updated);
    setState(() => _isEditing = false);
  }

  void _handleDelete(Task task, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(Task task, TaskProvider provider) async {
    if (task.isOverdue) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Task is overdue'),
          content: const Text('Do you want to complete or delete this overdue task?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Delete', style: TextStyle(color: _danger)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'complete'),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (action == 'delete') {
        await provider.deleteTask(task.id);
        if (mounted) Navigator.pop(context);
      } else if (action == 'complete') {
        await provider.toggleTask(task.id);
        await SoundService().playClick();
        HapticFeedback.lightImpact();
      }
      return;
    }

    await provider.toggleTask(task.id);
    await SoundService().playClick();
    HapticFeedback.lightImpact();
  }

  void _addSubtask(Task task, TaskProvider provider) {
    final t = _subtaskController.text.trim();
    if (t.isEmpty) return;
    provider.addSubtask(task.id, t);
    _subtaskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();

    final task = provider.tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => Task(id: '', title: '', startDate: DateTime.now(), endDate: DateTime.now(), createdAt: DateTime.now()),
    );

    if (task.id.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Task not found.', style: TextStyle(color: colors.onSurface)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Go back', style: TextStyle(color: _primary)),
              ),
            ],
          ),
        ),
      );
    }

    // Init edit fields once
    if (_titleCtrl.text.isEmpty && !_isEditing) _initEdit(task);

    final completedSubs = task.subtasks.where((s) => s.completed).length;
    final totalSubs = task.subtasks.length;
    final subPct = totalSubs > 0 ? (completedSubs / totalSubs * 100).round() : 0;

    final catData = _categoryData[task.category]!;
    final pColor = _priorities.firstWhere((p) => p.$1 == task.priority).$3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(width: 36, height: 36, child: Icon(Icons.close_rounded, color: colors.onSurface)),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Task' : 'Task Detail',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                  ),
                  if (_isEditing)
                    GestureDetector(
                      onTap: () => _saveEdit(task, context.read<TaskProvider>()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => context.read<TaskProvider>().togglePin(task.id),
                          child: Icon(
                            task.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            color: task.pinned ? _primary : colors.onSurface.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            _initEdit(task);
                            setState(() => _isEditing = true);
                          },
                          child: const Icon(Icons.edit_outlined, color: _primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _handleDelete(task, context.read<TaskProvider>()),
                          child: const Icon(Icons.delete_outline_rounded, color: _danger, size: 18),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title area
                  if (_isEditing)
                    _buildInput(context, _titleCtrl, 'Task title')
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _handleToggle(task, context.read<TaskProvider>()),
                          child: Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: task.completed ? _success : colors.outline.withOpacity(0.4), width: 2),
                              color: task.completed ? _success : Colors.transparent,
                            ),
                            child: task.completed ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              color: task.completed ? colors.onSurface.withOpacity(0.4) : colors.onSurface,
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              decorationColor: colors.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Status badges (view mode)
                  if (!_isEditing)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(color: catData.color, label: catData.label),
                        _Badge(color: pColor, label: task.priority.name, icon: Icons.flag_rounded),
                        if (task.isOverdue)
                          _Badge(color: _danger, label: 'Overdue', icon: Icons.warning_amber_rounded, bg: _danger.withOpacity(0.12)),
                        if (task.repeat != RepeatType.none)
                          _Badge(color: colors.onSurface.withOpacity(0.45), label: task.repeat.name, icon: Icons.repeat_rounded, bg: colors.onSurface.withOpacity(0.08)),
                      ],
                    ),

                  // Edit category
                  if (_isEditing) ...[
                    const _SectionLabel(label: 'Category'),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: Category.values.map((cat) {
                          final d = _categoryData[cat]!;
                          final selected = _editCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _editCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected ? d.color : d.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: selected ? null : Border.all(color: d.color.withOpacity(0.35)),
                                ),
                                child: Text(d.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : d.color)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const _SectionLabel(label: 'Priority'),
                    const SizedBox(height: 8),
                    Row(
                      children: _priorities.map((p) {
                        final (key, label, color) = p;
                        final active = _editPriority == key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _editPriority = key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? color : colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: active ? null : Border.all(color: color.withOpacity(0.35)),
                                ),
                                child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : color)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 4),

                  // Description
                  const _SectionLabel(label: 'Description'),
                  const SizedBox(height: 10),
                  if (_isEditing)
                    _buildTextArea(context, _descCtrl, 'Add description...')
                  else
                    Text(
                      task.description.isEmpty ? 'No description added.' : task.description,
                      style: TextStyle(fontSize: 15, height: 1.5, color: colors.onSurface.withOpacity(task.description.isEmpty ? 0.35 : 0.7)),
                    ),

                  const SizedBox(height: 20),

                  // Dates card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: _primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start', style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.5))),
                                  const SizedBox(height: 2),
                                  Text(DateFormat('MMM d, yyyy h:mm a').format(task.startDate),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: _danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deadline', style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.5))),
                                  const SizedBox(height: 2),
                                  if (_isEditing)
                                    GestureDetector(
                                      onTap: () async {
                                        final d = await showDatePicker(context: context, initialDate: _editEndDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                        if (d == null) return;
                                        final t = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(_editEndDate),
                                        );
                                        final time = t ?? TimeOfDay.fromDateTime(_editEndDate);
                                        final next = DateTime(d.year, d.month, d.day, time.hour, time.minute);
                                        if (mounted) setState(() => _editEndDate = next);
                                      },
                                      child: Text(DateFormat('MMM d, yyyy h:mm a').format(_editEndDate),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                                    )
                                  else
                                    Text(DateFormat('MMM d, yyyy h:mm a').format(task.endDate),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Progress card (if subtasks)
                  if (totalSubs > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionLabel(label: 'Progress'),
                              Text('$completedSubs/$totalSubs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: task.progress,
                              backgroundColor: _primary.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('$subPct% complete', style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Subtasks
                  _SectionLabel(label: 'Subtasks ($totalSubs)'),
                  const SizedBox(height: 10),
                  ...task.subtasks.map((s) => GestureDetector(
                    onTap: () => context.read<TaskProvider>().toggleSubtask(task.id, s.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: s.completed ? _success : colors.outline.withOpacity(0.4), width: 2),
                              color: s.completed ? _success : Colors.transparent,
                            ),
                            child: s.completed ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: s.completed ? colors.onSurface.withOpacity(0.4) : colors.onSurface,
                                decoration: s.completed ? TextDecoration.lineThrough : null,
                                decorationColor: colors.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                  // Add subtask
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          onSubmitted: (_) => _addSubtask(task, context.read<TaskProvider>()),
                          decoration: InputDecoration(
                            hintText: 'Add subtask...',
                            hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35), fontSize: 14),
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withOpacity(0.5))),
                          ),
                          style: TextStyle(fontSize: 14, color: colors.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _addSubtask(task, context.read<TaskProvider>()),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.add_rounded, size: 18, color: _primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Complete button
                  GestureDetector(
                    onTap: () => _handleToggle(task, context.read<TaskProvider>()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: task.completed ? colors.onSurface.withOpacity(0.08) : _success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            task.completed ? Icons.refresh_rounded : Icons.check_rounded,
                            color: task.completed ? colors.onSurface.withOpacity(0.5) : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            task.completed ? 'Mark as Pending' : 'Mark as Complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: task.completed ? colors.onSurface.withOpacity(0.5) : Colors.white,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildInput(BuildContext context, TextEditingController ctrl, String hint) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35)),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.onSurface),
    );
  }

  Widget _buildTextArea(BuildContext context, TextEditingController ctrl, String hint) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35)),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
      style: TextStyle(fontSize: 15, color: colors.onSurface),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;
  final Color? bg;
  const _Badge({required this.color, required this.label, this.icon, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CatD {
  final Color color;
  final String label;
  const _CatD({required this.color, required this.label});
}
