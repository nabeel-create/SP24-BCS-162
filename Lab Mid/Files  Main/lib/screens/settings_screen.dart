import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _soundKey = 'default';

  @override
  void initState() {
    super.initState();
    _loadSound();
  }

  Future<void> _loadSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _soundKey = prefs.getString('notification_sound') ?? 'default');
  }

  Future<void> _setSound(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', key);
    if (mounted) setState(() => _soundKey = key);
  }

  String _soundLabel() {
    switch (_soundKey) {
      case 'beep':
        return 'Beep';
      default:
        return 'Default';
    }
  }

  Future<void> _pickSound(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SoundOption(
              label: 'Default',
              selected: _soundKey == 'default',
              onTap: () => Navigator.pop(ctx, 'default'),
            ),
            _SoundOption(
              label: 'Beep',
              selected: _soundKey == 'beep',
              onTap: () => Navigator.pop(ctx, 'beep'),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await _setSound(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<TaskProvider>();
    final completedCount = provider.completedTasks.length;
    final totalCount = provider.tasks.length;

    const primary = Color(0xFF6C63FF);
    const success = Color(0xFF10B981);
    const warning = Color(0xFFF59E0B);
    const danger = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.onSurface)),

              const SizedBox(height: 20),

              // Appearance
              const _SectionLabel(label: 'Appearance'),
              const SizedBox(height: 8),
              _SettingCard(children: [
                _SettingRow(
                  iconColor: const Color(0xFF8B5CF6),
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  right: Switch(
                    value: provider.darkMode,
                    onChanged: (_) => provider.toggleDarkMode(),
                    activeThumbColor: primary,
                  ),
                  last: true,
                ),
              ]),

              const SizedBox(height: 20),

              // Notifications
              const _SectionLabel(label: 'Notifications'),
              const SizedBox(height: 8),
              _SettingCard(children: [
                _SettingRow(
                  iconColor: warning,
                  icon: Icons.notifications_rounded,
                  label: 'Enable Notifications',
                  right: Switch(
                    value: provider.notificationsEnabled,
                    onChanged: (_) async => provider.toggleNotifications(),
                    activeThumbColor: primary,
                  ),
                ),
                _SettingRow(
                  iconColor: const Color(0xFF8B5CF6),
                  icon: Icons.music_note_rounded,
                  label: 'Notification Sound',
                  value: _soundLabel(),
                  onTap: () => _pickSound(context),
                ),
                const _SettingRow(
                  iconColor: Color(0xFF3B82F6),
                  icon: Icons.access_time_rounded,
                  label: 'Task Reminders',
                  value: 'Before deadline',
                  last: true,
                ),
              ]),

              const SizedBox(height: 20),

              // Data
              const _SectionLabel(label: 'Data Management'),
              const SizedBox(height: 8),
              _SettingCard(children: [
                _SettingRow(
                  iconColor: success,
                  icon: Icons.download_rounded,
                  label: 'Export to CSV',
                  onTap: () async {
                    await ExportService().exportToCSV(provider.tasks);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tasks exported!')),
                      );
                    }
                  },
                ),
                _SettingRow(
                  iconColor: success,
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export to PDF',
                  onTap: () async {
                    await ExportService().exportToPDF(provider.tasks);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tasks exported!')),
                      );
                    }
                  },
                ),
                _SettingRow(
                  iconColor: success,
                  icon: Icons.email_rounded,
                  label: 'Export via Email',
                  onTap: () async {
                    await ExportService().exportToEmail(provider.tasks);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export ready to send!')),
                      );
                    }
                  },
                ),
                _SettingRow(
                  iconColor: const Color(0xFF3B82F6),
                  icon: Icons.auto_delete_rounded,
                  label: 'Auto-archive completed',
                  value: 'After 7 days',
                  right: Switch(
                    value: provider.autoArchiveCompleted,
                    onChanged: (_) => provider.toggleAutoArchiveCompleted(),
                    activeThumbColor: primary,
                  ),
                ),
                _SettingRow(
                  iconColor: success,
                  icon: Icons.delete_sweep_rounded,
                  label: 'Clear Completed',
                  value: '$completedCount tasks',
                  onTap: () => _confirm(context, 'Clear Completed Tasks',
                      'This will permanently delete all completed tasks. Are you sure?',
                      () => provider.clearCompleted()),
                ),
                _SettingRow(
                  iconColor: danger,
                  icon: Icons.warning_amber_rounded,
                  label: 'Clear All Tasks',
                  value: '$totalCount tasks',
                  onTap: () => _confirm(context, 'Clear All Tasks',
                      'This will permanently delete ALL tasks. This cannot be undone.',
                      () => provider.clearAll()),
                  isDanger: true,
                  last: true,
                ),
              ]),

              const SizedBox(height: 20),

              // About
              const _SectionLabel(label: 'About'),
              const SizedBox(height: 8),
              _SettingCard(children: [
                const _SettingRow(iconColor: primary, icon: Icons.info_outline_rounded, label: 'App Name', value: 'Nabeel Task Manager'),
                const _SettingRow(iconColor: primary, icon: Icons.tag_rounded, label: 'Version', value: '1.0.0'),
                _SettingRow(iconColor: primary, icon: Icons.storage_rounded, label: 'Total Tasks', value: '$totalCount', last: true),
              ]),

              const SizedBox(height: 20),

              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _StatItem(label: 'Total', value: totalCount, color: primary)),
                    Container(width: 1, height: 40, color: colors.outline.withOpacity(0.2)),
                    Expanded(child: _StatItem(label: 'Completed', value: completedCount, color: success)),
                    Container(width: 1, height: 40, color: colors.outline.withOpacity(0.2)),
                    Expanded(child: _StatItem(label: 'Pending', value: totalCount - completedCount, color: warning)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, String title, String message, VoidCallback action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { action(); Navigator.pop(ctx); },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String label;
  final String? value;
  final Widget? right;
  final VoidCallback? onTap;
  final bool last;
  final bool isDanger;

  const _SettingRow({
    required this.iconColor,
    required this.icon,
    required this.label,
    this.value,
    this.right,
    this.onTap,
    this.last = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final row = Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: colors.outline.withOpacity(0.15))),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDanger ? const Color(0xFFEF4444) : colors.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  if (value != null)
                    Text(value!, style: TextStyle(fontSize: 13, color: colors.onSurface.withOpacity(0.45))),
                  if (right != null) ...[
                    const SizedBox(width: 8),
                    right!,
                  ],
                  if (onTap != null && right == null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: colors.onSurface.withOpacity(0.3)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return row;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }
}

class _SoundOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SoundOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? const Color(0xFF6C63FF) : colors.onSurface.withOpacity(0.4),
      ),
      title: Text(label, style: TextStyle(color: colors.onSurface)),
    );
  }
}
