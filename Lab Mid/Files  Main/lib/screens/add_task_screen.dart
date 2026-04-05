import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController();

  Category _category = Category.work;
  Priority _priority = Priority.medium;
  RepeatType _repeat = RepeatType.none;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final List<int> _repeatDays = [];
  final List<Subtask> _subtasks = [];
  bool _isSubmitting = false;
  bool _pinTask = false;

  static const _primary = Color(0xFF6C63FF);

  static const _categoryData = {
    Category.work: _CatData(color: Color(0xFF6C63FF), label: 'Work'),
    Category.study: _CatData(color: Color(0xFF10B981), label: 'Study'),
    Category.personal: _CatData(color: Color(0xFFF59E0B), label: 'Personal'),
    Category.health: _CatData(color: Color(0xFFEF4444), label: 'Health'),
    Category.shopping: _CatData(color: Color(0xFF3B82F6), label: 'Shopping'),
    Category.other: _CatData(color: Color(0xFF8B5CF6), label: 'Other'),
  };

  static const _priorities = [
    _PriorityData(key: Priority.low, label: 'Low', color: Color(0xFF10B981)),
    _PriorityData(key: Priority.medium, label: 'Medium', color: Color(0xFFF59E0B)),
    _PriorityData(key: Priority.high, label: 'High', color: Color(0xFFEF4444)),
  ];

  static const _repeats = [
    (RepeatType.none, 'None'),
    (RepeatType.daily, 'Daily'),
    (RepeatType.weekly, 'Weekly'),
  ];

  static const _weekdays = [
    (DateTime.monday, 'M'),
    (DateTime.tuesday, 'T'),
    (DateTime.wednesday, 'W'),
    (DateTime.thursday, 'T'),
    (DateTime.friday, 'F'),
    (DateTime.saturday, 'S'),
    (DateTime.sunday, 'S'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final t = _subtaskController.text.trim();
    if (t.isEmpty) return;
    setState(() => _subtasks.add(Subtask(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: t,
    )));
    _subtaskController.clear();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_repeat == RepeatType.weekly && _repeatDays.isEmpty) {
        _repeatDays.add(_endDate.weekday);
      }
      await context.read<TaskProvider>().addTask(
        title: title,
        description: _descController.text.trim(),
        category: _category,
        priority: _priority,
        repeat: _repeat,
        repeatDays: _repeat == RepeatType.weekly ? _repeatDays : const [],
        startDate: _startDate,
        endDate: _endDate,
        subtasks: _subtasks,
        pinned: _pinTask,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                    child: SizedBox(
                      width: 36, height: 36,
                      child: Icon(Icons.close_rounded, color: colors.onSurface),
                    ),
                  ),
                  Expanded(
                    child: Text('New Task',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  ),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(_isSubmitting ? 0.6 : 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isSubmitting ? 'Saving...' : 'Save',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const _FormLabel(label: 'Title *'),
                  const SizedBox(height: 8),
                  _buildInput(_titleController, 'What needs to be done?', autofocus: true),

                  const SizedBox(height: 20),

                  // Description
                  const _FormLabel(label: 'Description'),
                  const SizedBox(height: 8),
                  _buildTextArea(_descController, 'Add more details...'),

                  const SizedBox(height: 20),

                  // Category
                  const _FormLabel(label: 'Category'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: Category.values.map((cat) {
                        final d = _categoryData[cat]!;
                        final selected = _category == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected ? d.color : d.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: selected ? null : Border.all(color: d.color.withOpacity(0.35)),
                              ),
                              child: Text(
                                d.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : d.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pin task
                  const _FormLabel(label: 'Pin Task'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PinChip(
                        active: !_pinTask,
                        label: 'Normal',
                        icon: Icons.push_pin_outlined,
                        onTap: () => setState(() => _pinTask = false),
                      ),
                      const SizedBox(width: 8),
                      _PinChip(
                        active: _pinTask,
                        label: 'Pinned',
                        icon: Icons.push_pin_rounded,
                        onTap: () => setState(() => _pinTask = true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Priority
                  const _FormLabel(label: 'Priority'),
                  const SizedBox(height: 8),
                  Row(
                    children: _priorities.map((p) {
                      final active = _priority == p.key;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = p.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? p.color : colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: active ? null : Border.all(color: p.color.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flag_rounded, size: 14, color: active ? Colors.white : p.color),
                                  const SizedBox(width: 6),
                                  Text(p.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : p.color)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormLabel(label: 'Start Date'),
                            const SizedBox(height: 8),
                            _DateButton(
                              date: _startDate,
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d == null) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_startDate),
                                );
                                final time = t ?? TimeOfDay.fromDateTime(_startDate);
                                final next = DateTime(d.year, d.month, d.day, time.hour, time.minute);
                                if (mounted) setState(() => _startDate = next);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormLabel(label: 'End Date'),
                            const SizedBox(height: 8),
                            _DateButton(
                              date: _endDate,
                          onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d == null) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_endDate),
                                );
                                final time = t ?? TimeOfDay.fromDateTime(_endDate);
                                final next = DateTime(d.year, d.month, d.day, time.hour, time.minute);
                                if (mounted) setState(() => _endDate = next);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Repeat
                  const _FormLabel(label: 'Repeat'),
                  const SizedBox(height: 8),
                  Row(
                    children: _repeats.map((r) {
                      final (key, label) = r;
                      final active = _repeat == key;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _repeat = key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? _primary : colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: active ? null : Border.all(color: colors.outline.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.repeat_rounded, size: 13, color: active ? Colors.white : colors.onSurface.withOpacity(0.5)),
                                  const SizedBox(width: 6),
                                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : colors.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  if (_repeat == RepeatType.weekly) ...[
                    const _FormLabel(label: 'Repeat Days'),
                    const SizedBox(height: 8),
                    Row(
                      children: _weekdays.map((d) {
                        final (value, label) = d;
                        final active = _repeatDays.contains(value);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (active) {
                                    _repeatDays.remove(value);
                                  } else {
                                    _repeatDays.add(value);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? _primary : colors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: active ? null : Border.all(color: colors.outline.withOpacity(0.25)),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : colors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Subtasks
                  _FormLabel(label: 'Subtasks (${_subtasks.length})'),
                  const SizedBox(height: 8),
                  ..._subtasks.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank_rounded, size: 14, color: _primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.title, style: TextStyle(fontSize: 14, color: colors.onSurface))),
                          GestureDetector(
                            onTap: () => setState(() => _subtasks.removeAt(i)),
                            child: Icon(Icons.close_rounded, size: 14, color: colors.onSurface.withOpacity(0.35)),
                          ),
                        ],
                      ),
                    );
                  }),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          onSubmitted: (_) => _addSubtask(),
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
                        onTap: _addSubtask,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, size: 18, color: _primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {bool autofocus = false}) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35), fontSize: 15),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.5))),
      ),
      style: TextStyle(fontSize: 15, color: colors.onSurface),
    );
  }

  Widget _buildTextArea(TextEditingController ctrl, String hint) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35), fontSize: 15),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.outline.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.5))),
      ),
      style: TextStyle(fontSize: 15, color: colors.onSurface),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
      ),
    );
  }
}

class _PinChip extends StatelessWidget {
  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PinChip({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const primary = Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: colors.outline.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : colors.onSurface.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Text(
          DateFormat('yyyy-MM-dd HH:mm').format(date),
          style: TextStyle(fontSize: 15, color: colors.onSurface),
        ),
      ),
    );
  }
}

class _CatData {
  final Color color;
  final String label;
  const _CatData({required this.color, required this.label});
}

class _PriorityData {
  final Priority key;
  final String label;
  final Color color;
  const _PriorityData({required this.key, required this.label, required this.color});
}
