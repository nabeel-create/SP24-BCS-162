import 'dart:convert';

enum Category { work, study, personal, health, shopping, other }

enum Priority { low, medium, high }

enum RepeatType { none, daily, weekly }

class Subtask {
  final String id;
  String title;
  bool completed;

  Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
    );
  }

  Subtask copyWith({String? id, String? title, bool? completed}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

class Task {
  final String id;
  String title;
  String description;
  Category category;
  Priority priority;
  RepeatType repeat;
  List<int> repeatDays;
  DateTime startDate;
  DateTime endDate;
  bool completed;
  bool pinned;
  List<Subtask> subtasks;
  final DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = Category.work,
    this.priority = Priority.medium,
    this.repeat = RepeatType.none,
    this.repeatDays = const [],
    required this.startDate,
    required this.endDate,
    this.completed = false,
    this.pinned = false,
    this.subtasks = const [],
    required this.createdAt,
    this.completedAt,
  });

  double get progress {
    if (subtasks.isEmpty) return completed ? 1.0 : 0.0;
    final done = subtasks.where((s) => s.completed).length;
    return done / subtasks.length;
  }

  bool get isOverdue {
    if (completed) return false;
    return endDate.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'repeat': repeat.name,
      'repeatDays': jsonEncode(repeatDays),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'pinned': pinned ? 1 : 0,
      'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final subtasksJson = jsonDecode(map['subtasks'] as String) as List;
    final repeatDaysJson = jsonDecode(map['repeatDays'] as String) as List;
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: Category.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => Category.work,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      repeat: RepeatType.values.firstWhere(
        (e) => e.name == map['repeat'],
        orElse: () => RepeatType.none,
      ),
      repeatDays: repeatDaysJson.cast<int>(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      completed: (map['completed'] as int) == 1,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      subtasks: subtasksJson
          .map((s) => Subtask.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Category? category,
    Priority? priority,
    RepeatType? repeat,
    List<int>? repeatDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? completed,
    bool? pinned,
    List<Subtask>? subtasks,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      repeat: repeat ?? this.repeat,
      repeatDays: repeatDays ?? this.repeatDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completed: completed ?? this.completed,
      pinned: pinned ?? this.pinned,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
