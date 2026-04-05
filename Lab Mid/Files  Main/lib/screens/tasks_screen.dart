import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/sound_service.dart';
import '../widgets/task_card_widget.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

enum TaskFilter { all, pending, completed, today, repeated, overdue }
enum TaskSort { date, priority, pinned }

class TasksScreen extends StatefulWidget {
  final TaskFilter initialFilter;
  const TasksScreen({super.key, this.initialFilter = TaskFilter.all});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.pinned;
  String _search = '';
  final _searchController = TextEditingController();

  static const _primary = Color(0xFF6C63FF);
  static const _danger = Color(0xFFEF4444);

  Future<void> _confirmDelete(BuildContext context, Task task, TaskProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"? This can’t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteTask(task.id);
    }
  }

  Future<void> _handleToggle(BuildContext context, Task task, TaskProvider provider) async {
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

  List<Task> _getFilteredTasks(TaskProvider provider) {
    List<Task> tasks;
    switch (_filter) {
      case TaskFilter.pending:
        tasks = provider.pendingTasks;
        break;
      case TaskFilter.completed:
        tasks = provider.completedTasks;
        break;
      case TaskFilter.today:
        tasks = provider.todayTasks;
        break;
      case TaskFilter.repeated:
        tasks = provider.repeatingTasks;
        break;
      case TaskFilter.overdue:
        tasks = provider.tasks.where((t) => t.isOverdue).toList();
        break;
      default:
        tasks = provider.tasks;
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.category.name.toLowerCase().contains(q))
          .toList();
    }

    int priorityRank(Priority p) {
      switch (p) {
        case Priority.high:
          return 3;
        case Priority.medium:
          return 2;
        case Priority.low:
          return 1;
      }
    }

    tasks.sort((a, b) {
      switch (_sort) {
        case TaskSort.priority:
          final pr = priorityRank(b.priority).compareTo(priorityRank(a.priority));
          if (pr != 0) return pr;
          return a.endDate.compareTo(b.endDate);
        case TaskSort.date:
          return a.endDate.compareTo(b.endDate);
        case TaskSort.pinned:
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return a.endDate.compareTo(b.endDate);
      }
    });
    return tasks;
  }

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();
    final tasks = _getFilteredTasks(provider);
    final overdueCount = provider.tasks.where((t) => t.isOverdue).length;

    final filters = [
      (TaskFilter.all, 'All', Icons.layers_rounded),
      (TaskFilter.pending, 'Pending', Icons.access_time_rounded),
      (TaskFilter.completed, 'Done', Icons.check_circle_outline_rounded),
      (TaskFilter.today, 'Today', Icons.wb_sunny_rounded),
      (TaskFilter.repeated, 'Repeat', Icons.repeat_rounded),
      (TaskFilter.overdue, 'Overdue ($overdueCount)', Icons.warning_amber_rounded),
    ];

    String sortLabel() {
      switch (_sort) {
        case TaskSort.priority:
          return 'Priority';
        case TaskSort.date:
          return 'Date';
        case TaskSort.pinned:
          return 'Pinned';
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Tasks',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.onSurface)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded, size: 16, color: colors.onSurface.withOpacity(0.35)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.35), fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: TextStyle(fontSize: 15, color: colors.onSurface),
                      ),
                    ),
                    if (_search.isNotEmpty)
                      GestureDetector(
                        onTap: () { _searchController.clear(); setState(() => _search = ''); },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close_rounded, size: 16, color: colors.onSurface.withOpacity(0.35)),
                        ),
                      )
                    else
                      const SizedBox(width: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: filters.map((f) {
                  final (key, label, icon) = f;
                  final active = _filter == key;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _primary : colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: active ? null : Border.all(color: colors.outline.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: active ? Colors.white : colors.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: active ? Colors.white : colors.onSurface.withOpacity(0.5),
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Sort row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Sort by', style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.5))),
                  const SizedBox(width: 8),
                  PopupMenuButton<TaskSort>(
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: TaskSort.pinned, child: Text('Pinned first')),
                      PopupMenuItem(value: TaskSort.date, child: Text('Date')),
                      PopupMenuItem(value: TaskSort.priority, child: Text('Priority')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(sortLabel(), style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.8))),
                          const SizedBox(width: 6),
                          Icon(Icons.expand_more_rounded, size: 16, color: colors.onSurface.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Task count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.5)),
                ),
              ),
            ),

            // Task list
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checklist_rounded, size: 56, color: colors.onSurface.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text('No tasks found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.onSurface)),
                          const SizedBox(height: 4),
                          Text(
                            _search.isNotEmpty ? 'Try a different search term' : 'Tap + to add a new task',
                            style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        if (tasks.where((t) => t.pinned).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...tasks.where((t) => t.pinned).map((task) => TaskCardWidget(
                                key: ValueKey('pinned_${task.id}'),
                                task: task,
                                keyPrefix: 'pinned-',
                                onToggle: () => _handleToggle(context, task, provider),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                                onDelete: () => _confirmDelete(context, task, provider),
                                onPin: () => provider.togglePin(task.id),
                              )),
                          const SizedBox(height: 12),
                          Text(
                            'All Tasks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ...tasks.where((t) => !t.pinned).map((task) => TaskCardWidget(
                              key: ValueKey(task.id),
                              task: task,
                              keyPrefix: 'list-',
                              onToggle: () => _handleToggle(context, task, provider),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                              onDelete: () => _confirmDelete(context, task, provider),
                              onPin: () => provider.togglePin(task.id),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
