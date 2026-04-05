import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/sound_service.dart';
import '../widgets/task_card_widget.dart';
import 'add_task_screen.dart';
import 'tasks_screen.dart';
import 'task_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _danger = Color(0xFFEF4444);
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return tasks;
    return tasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.name.toLowerCase().contains(q))
        .toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    final allTasks = provider.tasks;
    final searchResults = _filterTasks(allTasks);
    final completedTasks = provider.completedTasks;
    final pendingTasks = provider.pendingTasks;
    final todayTasks = provider.todayTasks;
    final todayPending = todayTasks.where((t) => !t.completed).toList();
    final todayDone = todayTasks.where((t) => t.completed).toList();
    final progress = provider.overallProgress;
    final pinnedTasks = provider.tasks.where((t) => t.pinned).toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));

    const primary = Color(0xFF6C63FF);
    const warning = Color(0xFFF59E0B);
    const success = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(today, style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      Text('Good ${_getGreeting()}!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.onSurface)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_search.trim().isNotEmpty) ...[
                Text('Search Results',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 8),
                Text('${searchResults.length} task${searchResults.length != 1 ? 's' : ''} found',
                    style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.5))),
                const SizedBox(height: 12),
                if (searchResults.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outline.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text('No matching tasks', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                    ),
                  )
                else
                  ...searchResults.take(8).map((task) => TaskCardWidget(
                        key: ValueKey('search-${task.id}'),
                        task: task,
                        keyPrefix: 'search-',
                        onToggle: () => _handleToggle(context, task, provider),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                        onDelete: () => _confirmDelete(context, task, provider),
                        onPin: () => provider.togglePin(task.id),
                      )),
              ] else ...[
              // Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall Progress',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text('${completedTasks.length} of ${allTasks.length} tasks done',
                              style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF))),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('${todayDone.length} completed today',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _CircularProgressRing(progress: progress),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Total', value: allTasks.length, color: primary, icon: Icons.layers_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Pending', value: pendingTasks.length, color: warning, icon: Icons.access_time_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Done', value: completedTasks.length, color: success, icon: Icons.check_circle_outline_rounded)),
                ],
              ),

              const SizedBox(height: 20),

              // Quick search (under progress)
              Container(
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
                          hintText: 'Quick search tasks...',
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
                        onTap: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
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

              const SizedBox(height: 20),

              if (pinnedTasks.isNotEmpty) ...[
                Text('Pinned',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 12),
                ...pinnedTasks.take(3).map((task) => TaskCardWidget(
                      key: ValueKey('pinned-${task.id}'),
                      task: task,
                      keyPrefix: 'pinned-',
                      onToggle: () => _handleToggle(context, task, provider),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                      onDelete: () => _confirmDelete(context, task, provider),
                      onPin: () => provider.togglePin(task.id),
                    )),
                const SizedBox(height: 20),
              ],

              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Tasks",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasksScreen(initialFilter: TaskFilter.today)),
                    ),
                    child: const Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primary)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (todayPending.isEmpty && todayDone.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outline.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny_rounded, size: 40, color: colors.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('No tasks for today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.onSurface)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first task', style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                )
              else ...[
                ...todayPending.take(5).map((task) => TaskCardWidget(
                      key: ValueKey('today-pending-${task.id}'),
                      task: task,
                      keyPrefix: 'today-pending-',
                      onToggle: () => _handleToggle(context, task, provider),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                      onDelete: () => _confirmDelete(context, task, provider),
                      onPin: () => provider.togglePin(task.id),
                    )),
                if (todayDone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.outline.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Completed', style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.4))),
                      ),
                      Expanded(child: Divider(color: colors.outline.withOpacity(0.3))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...todayDone.take(3).map((task) => TaskCardWidget(
                        key: ValueKey('today-done-${task.id}'),
                        task: task,
                        keyPrefix: 'today-done-',
                        onToggle: () => _handleToggle(context, task, provider),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
                        onPin: () => provider.togglePin(task.id),
                      )),
                ],
              ],

              const SizedBox(height: 20),

              // Quick Access
              Text('Quick Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _QuickCard(label: 'All Tasks', icon: Icons.list_rounded, color: primary, count: allTasks.length)),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickCard(label: 'Completed', icon: Icons.check_circle_rounded, color: success, count: completedTasks.length)),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickCard(label: 'Repeated', icon: Icons.repeat_rounded, color: warning, count: provider.repeatingTasks.length)),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressRing extends StatelessWidget {
  final double progress;
  const _CircularProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$pct%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const Text('Done', style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _QuickCard({required this.label, required this.icon, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}
