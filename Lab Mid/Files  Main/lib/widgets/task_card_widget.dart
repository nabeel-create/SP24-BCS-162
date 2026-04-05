import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final String keyPrefix;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
    this.onPin,
    this.keyPrefix = '',
  });

  static const _categoryColors = {
    Category.work: Color(0xFF6C63FF),
    Category.study: Color(0xFF10B981),
    Category.personal: Color(0xFFF59E0B),
    Category.health: Color(0xFFEF4444),
    Category.shopping: Color(0xFF3B82F6),
    Category.other: Color(0xFF8B5CF6),
  };

  static const _categoryIcons = {
    Category.work: Icons.work_outline_rounded,
    Category.study: Icons.menu_book_rounded,
    Category.personal: Icons.person_outline_rounded,
    Category.health: Icons.favorite_border_rounded,
    Category.shopping: Icons.shopping_bag_outlined,
    Category.other: Icons.grid_view_rounded,
  };

  static const _priorityColors = {
    Priority.low: Color(0xFF10B981),
    Priority.medium: Color(0xFFF59E0B),
    Priority.high: Color(0xFFEF4444),
  };
  static const _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final catColor = _categoryColors[task.category] ?? const Color(0xFF6C63FF);
    final pColor = _priorityColors[task.priority] ?? const Color(0xFFF59E0B);
    final catIcon = _categoryIcons[task.category] ?? Icons.grid_view_rounded;

    final completedSubs = task.subtasks.where((s) => s.completed).length;
    final totalSubs = task.subtasks.length;
    final subProgress = totalSubs > 0 ? completedSubs / totalSubs : 0.0;

    final card = Opacity(
      opacity: task.completed ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: colors.shadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category bar
            Container(width: 4, color: catColor),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggle,
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: task.completed ? catColor : colors.outline.withOpacity(0.4),
                                width: 2,
                              ),
                              color: task.completed ? catColor : Colors.transparent,
                            ),
                            child: task.completed
                                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title + description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: task.completed ? colors.onSurface.withOpacity(0.4) : colors.onSurface,
                                  decoration: task.completed ? TextDecoration.lineThrough : null,
                                  decorationColor: colors.onSurface.withOpacity(0.4),
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  task.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.5)),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (onPin != null)
                          GestureDetector(
                            onTap: onPin,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, top: 2),
                              child: Icon(
                                task.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                size: 16,
                                color: task.pinned ? catColor : colors.onSurface.withOpacity(0.35),
                              ),
                            ),
                          ),

                        // Delete button
                        if (onDelete != null)
                          GestureDetector(
                            onTap: onDelete,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Icon(Icons.delete_outline_rounded, size: 16, color: colors.onSurface.withOpacity(0.3)),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Footer
                    Row(
                      children: [
                        // Badges
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Badge(
                                icon: catIcon,
                                label: task.category.name,
                                color: catColor,
                              ),
                              _Badge(
                                icon: Icons.flag_rounded,
                                label: task.priority.name,
                                color: pColor,
                              ),
                              if (task.isOverdue)
                                _Badge(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'Overdue',
                                  color: _danger,
                                  bg: _danger.withOpacity(0.12),
                                ),
                              if (task.repeat != RepeatType.none)
                                _Badge(
                                  icon: Icons.repeat_rounded,
                                  label: task.repeat.name,
                                  color: colors.onSurface.withOpacity(0.45),
                                  bg: colors.onSurface.withOpacity(0.08),
                                ),
                            ],
                          ),
                        ),

                        // Right: subtask count + date
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (totalSubs > 0) ...[
                              Text('$completedSubs/$totalSubs',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.onSurface.withOpacity(0.5))),
                              const SizedBox(width: 8),
                            ],
                            Icon(Icons.calendar_today_rounded, size: 11, color: colors.onSurface.withOpacity(0.35)),
                            const SizedBox(width: 3),
                            Text(DateFormat('MMM d').format(task.endDate),
                                style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.35))),
                          ],
                        ),
                      ],
                    ),

                    if (!task.completed) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Reminder at ${DateFormat('h:mm a').format(task.endDate)}',
                        style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.45)),
                      ),
                    ],

                    // Subtask progress bar
                    if (totalSubs > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: subProgress,
                          backgroundColor: catColor.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(catColor),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Slidable(
      key: ValueKey('$keyPrefix${task.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onToggle(),
            backgroundColor: task.completed ? const Color(0xFF6B7280) : const Color(0xFF10B981),
            foregroundColor: Colors.white,
            icon: task.completed ? Icons.refresh_rounded : Icons.check_rounded,
            label: task.completed ? 'Undo' : 'Done',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bg;

  const _Badge({required this.icon, required this.label, required this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
