import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/sound_service.dart';
import '../widgets/task_card_widget.dart';
import 'task_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _categoryData = {
    Category.work: _CatData(color: Color(0xFF6C63FF), icon: Icons.work_outline_rounded, label: 'Work'),
    Category.study: _CatData(color: Color(0xFF10B981), icon: Icons.menu_book_rounded, label: 'Study'),
    Category.personal: _CatData(color: Color(0xFFF59E0B), icon: Icons.person_outline_rounded, label: 'Personal'),
    Category.health: _CatData(color: Color(0xFFEF4444), icon: Icons.favorite_border_rounded, label: 'Health'),
    Category.shopping: _CatData(color: Color(0xFF3B82F6), icon: Icons.shopping_bag_outlined, label: 'Shopping'),
    Category.other: _CatData(color: Color(0xFF8B5CF6), icon: Icons.grid_view_rounded, label: 'Other'),
  };

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider provider,
    Category category,
    String label,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category Tasks'),
        content: Text("Delete $count task${count == 1 ? '' : 's'} in $label? This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteCategoryTasks(category);
    }
  }

  void _openCategory(BuildContext context, Category category, String label, int count) {
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tasks in $label category.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CategoryTasksScreen(category: category, label: label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();
    final counts = provider.categoryCounts;
    final nonEmpty = Category.values.where((c) => (counts[c] ?? 0) > 0).length;
    final allTasks = provider.tasks;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final availableWidth = maxWidth - 40; // matches horizontal padding (20 + 20)
                  final itemWidth = availableWidth > 0 ? (availableWidth - 12) / 2 : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categories',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.onSurface)),
                        const SizedBox(height: 4),
                        Text('${provider.tasks.length} total tasks across $nonEmpty categories',
                            style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 16),
                        if (itemWidth <= 0)
                          const SizedBox.shrink()
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: Category.values.map((cat) {
                              final d = _categoryData[cat]!;
                              final count = counts[cat] ?? 0;
                              return SizedBox(
                                width: itemWidth,
                                child: GestureDetector(
                                  onTap: () => _openCategory(context, cat, d.label, count),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: d.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: d.color.withOpacity(0.25)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: d.color,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(d.icon, color: Colors.white, size: 20),
                                            ),
                                            if (count > 0)
                                              GestureDetector(
                                                onTap: () => _confirmDelete(context, provider, cat, d.label, count),
                                                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(d.label,
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: d.color)),
                                        const SizedBox(height: 2),
                                        Text('$count tasks',
                                            style: TextStyle(fontSize: 13, color: d.color.withOpacity(0.8))),
                                        const SizedBox(height: 6),
                                        Builder(builder: (_) {
                                          final completed = allTasks.where((t) => t.category == cat && t.completed).length;
                                          final pending = allTasks.where((t) => t.category == cat && !t.completed).length;
                                          return Text(
                                            'Completed $completed • Pending $pending',
                                            style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.45)),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CatData {
  final Color color;
  final IconData icon;
  final String label;
  const _CatData({required this.color, required this.icon, required this.label});
}

class _CategoryTasksScreen extends StatelessWidget {
  final Category category;
  final String label;
  static const _danger = Color(0xFFEF4444);

  const _CategoryTasksScreen({required this.category, required this.label});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();
    final tasks = provider.getTasksByCategory(category).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.endDate.compareTo(b.endDate);
      });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(width: 36, height: 36, child: Icon(Icons.arrow_back_rounded, color: colors.onSurface)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$label Tasks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text('No tasks in $label', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: tasks.map((task) {
                        return TaskCardWidget(
                          key: ValueKey(task.id),
                          task: task,
                          keyPrefix: 'cat-',
                          onToggle: () => _handleToggle(context, task, provider),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                          onDelete: () => _confirmDelete(context, task, provider),
                          onPin: () => provider.togglePin(task.id),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

