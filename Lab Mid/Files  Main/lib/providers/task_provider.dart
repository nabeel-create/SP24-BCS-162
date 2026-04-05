import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _autoArchiveCompleted = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoArchiveCompleted => _autoArchiveCompleted;

  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();
  List<Task> get pendingTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get repeatingTasks => _tasks.where((t) => t.repeat != RepeatType.none).toList();

  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      return t.endDate.isBefore(now.add(const Duration(days: 1))) ||
          (t.startDate.year == now.year &&
              t.startDate.month == now.month &&
              t.startDate.day == now.day);
    }).toList();
  }

  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    return completedTasks.length / _tasks.length;
  }

  List<Task> getTasksByCategory(Category category) {
    return _tasks.where((t) => t.category == category).toList();
  }

  Map<Category, int> get categoryCounts {
    final counts = <Category, int>{};
    for (final cat in Category.values) {
      counts[cat] = _tasks.where((t) => t.category == cat).length;
    }
    return counts;
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadPrefs();
      _tasks = await _db.getAllTasks();
      if (_autoArchiveCompleted) {
        await _archiveOldCompleted();
      }
      await _normalizeRepeatingTasks();
      if (_notificationsEnabled) {
        for (final t in _tasks) {
          await _notifications.scheduleTaskReminder(t);
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoArchiveCompleted = prefs.getBool('auto_archive_completed') ?? false;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? _notificationsEnabled;
  }

  Future<void> _saveAutoArchive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_archive_completed', _autoArchiveCompleted);
  }

  Future<void> _normalizeRepeatingTasks() async {
    if (_tasks.isEmpty) return;
    final now = DateTime.now();
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.completed) continue;
      if (task.repeat == RepeatType.none) continue;
      final updated = _nextRepeatInstance(task, now, resetIfCompleted: false);
      if (updated != null) {
        _tasks[i] = updated;
        await _db.updateTask(updated);
      }
    }
  }

  Task? _nextRepeatInstance(Task task, DateTime now, {required bool resetIfCompleted}) {
    if (task.repeat == RepeatType.none) return null;

    final needsReset = resetIfCompleted ? task.completed : task.endDate.isBefore(now);
    if (!needsReset) return null;

    final duration = task.endDate.difference(task.startDate);
    DateTime nextEnd;

    if (task.repeat == RepeatType.daily) {
      nextEnd = task.endDate;
      while (!nextEnd.isAfter(now)) {
        nextEnd = nextEnd.add(const Duration(days: 1));
      }
    } else {
      final days = task.repeatDays.isEmpty ? [task.endDate.weekday] : task.repeatDays;
      final base = DateTime(task.endDate.year, task.endDate.month, task.endDate.day, task.endDate.hour, task.endDate.minute);
      DateTime? candidate;
      for (var i = 0; i <= 14; i++) {
        final d = base.add(Duration(days: i));
        if (days.contains(d.weekday) && d.isAfter(now)) {
          candidate = d;
          break;
        }
      }
      nextEnd = candidate ?? base.add(const Duration(days: 7));
    }

    final nextStart = nextEnd.subtract(duration);
    return task.copyWith(
      startDate: nextStart,
      endDate: nextEnd,
      completed: false,
      completedAt: null,
    );
  }

  Future<void> addTask({
    required String title,
    String description = '',
    required Category category,
    required Priority priority,
    required RepeatType repeat,
    List<int> repeatDays = const [],
    required DateTime startDate,
    required DateTime endDate,
    List<Subtask> subtasks = const [],
    bool pinned = false,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      repeat: repeat,
      repeatDays: repeatDays,
      startDate: startDate,
      endDate: endDate,
      subtasks: subtasks,
      pinned: pinned,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(task);
    _tasks.insert(0, task);
    if (_notificationsEnabled) {
      await _notifications.scheduleTaskReminder(task);
    }
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
      if (_notificationsEnabled) {
        await _notifications.scheduleTaskReminder(task);
      }
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    await _notifications.cancelTaskReminder(id);
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    final completing = !task.completed;
    final updated = task.copyWith(
      completed: completing,
      completedAt: completing ? DateTime.now() : null,
      subtasks: completing
          ? task.subtasks.map((s) => s.copyWith(completed: true)).toList()
          : task.subtasks,
    );

    Task? nextTask;
    if (completing && task.repeat != RepeatType.none) {
      final next = _nextRepeatInstance(updated, DateTime.now(), resetIfCompleted: true);
      if (next != null) {
        nextTask = next.copyWith(
          id: const Uuid().v4(),
          createdAt: DateTime.now(),
          completed: false,
          completedAt: null,
        );
      }
    }

    _tasks[idx] = updated;
    await _db.updateTask(updated);

    if (nextTask != null) {
      await _db.insertTask(nextTask);
      _tasks.insert(0, nextTask);
    }

    if (_notificationsEnabled) {
      if (updated.completed) {
        await _notifications.cancelTaskReminder(updated.id);
      } else {
        await _notifications.scheduleTaskReminder(updated);
      }
      if (nextTask != null) {
        await _notifications.scheduleTaskReminder(nextTask);
      }
    } else {
      await _notifications.cancelTaskReminder(updated.id);
      if (nextTask != null) {
        await _notifications.cancelTaskReminder(nextTask.id);
      }
    }
    notifyListeners();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx == -1) return;
    final task = _tasks[taskIdx];
    final subtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) return s.copyWith(completed: !s.completed);
      return s;
    }).toList();
    final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.completed);
    final updated = task.copyWith(
      subtasks: subtasks,
      completed: allDone,
      completedAt: allDone ? DateTime.now() : task.completedAt,
    );
    _tasks[taskIdx] = updated;
    await _db.updateTask(updated);
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    final updated = task.copyWith(pinned: !task.pinned);
    _tasks[idx] = updated;
    await _db.updateTask(updated);
    notifyListeners();
  }

  Future<void> addSubtask(String taskId, String title) async {
    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx == -1) return;
    final task = _tasks[taskIdx];
    final subtask = Subtask(id: const Uuid().v4(), title: title);
    final updated = task.copyWith(subtasks: [...task.subtasks, subtask]);
    _tasks[taskIdx] = updated;
    await _db.updateTask(updated);
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    await _db.deleteCompletedTasks();
    for (final t in _tasks.where((t) => t.completed)) {
      await _notifications.cancelTaskReminder(t.id);
    }
    _tasks.removeWhere((t) => t.completed);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _db.deleteAllTasks();
    for (final t in _tasks) {
      await _notifications.cancelTaskReminder(t.id);
    }
    _tasks.clear();
    notifyListeners();
  }


  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    if (_notificationsEnabled) {
      final granted = await _notifications.ensurePermissions();
      if (!granted) {
        _notificationsEnabled = false;
        await prefs.setBool('notifications_enabled', _notificationsEnabled);
      } else {
        for (final t in _tasks) {
          _notifications.scheduleTaskReminder(t);
        }
      }
    } else {
      for (final t in _tasks) {
        _notifications.cancelTaskReminder(t.id);
      }
    }
    notifyListeners();
  }

  Future<void> toggleAutoArchiveCompleted() async {
    _autoArchiveCompleted = !_autoArchiveCompleted;
    await _saveAutoArchive();
    if (_autoArchiveCompleted) {
      await _archiveOldCompleted();
    }
    notifyListeners();
  }

  Future<void> _archiveOldCompleted() async {
    if (_tasks.isEmpty) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toRemove = _tasks.where((t) => t.completed && t.completedAt != null && t.completedAt!.isBefore(cutoff)).toList();
    if (toRemove.isEmpty) return;
    await _db.deleteCompletedBefore(cutoff);
    for (final t in toRemove) {
      await _notifications.cancelTaskReminder(t.id);
    }
    _tasks.removeWhere((t) => t.completed && t.completedAt != null && t.completedAt!.isBefore(cutoff));
  }

  Future<void> deleteCategoryTasks(Category category) async {
    await _db.deleteTasksByCategory(category);
    for (final t in _tasks.where((t) => t.category == category)) {
      await _notifications.cancelTaskReminder(t.id);
    }
    _tasks.removeWhere((t) => t.category == category);
    notifyListeners();
  }
}
