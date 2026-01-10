// lib/core/models/task.dart
import '../enums/task_priority.dart';
import '../enums/task_status.dart';
import 'task_step.dart';
import 'dart:convert';

class Task {
  int? id;
  String userId;
  String title;
  TaskPriority priority;
  DateTime? deadline;
  DateTime? startDate;
  int estimatedMinutes;
  TaskStatus status;
  DateTime createdAt;
  DateTime? updatedAt;
  bool isSelectedForToday;
  DateTime? selectedDate;
  List<TaskStep> steps;

  Task({
    this.id,
    required this.userId,
    required this.title,
    required this.priority,
    this.deadline,
    this.startDate,
    required this.estimatedMinutes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isSelectedForToday = false,
    this.selectedDate,
    this.steps = const [],
  });

  // Create a copy with updated values
  Task copyWith({
    int? id,
    String? userId,
    String? title,
    TaskPriority? priority,
    DateTime? deadline,
    DateTime? startDate,
    int? estimatedMinutes,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelectedForToday,
    DateTime? selectedDate,
    List<TaskStep>? steps,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      startDate: startDate ?? this.startDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelectedForToday: isSelectedForToday ?? this.isSelectedForToday,
      selectedDate: selectedDate ?? this.selectedDate,
      steps: steps ?? this.steps,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_selected_for_today': isSelectedForToday ? 1 : 0,
      'selected_date': selectedDate?.toIso8601String(),
      'steps': jsonEncode(steps.map((e) => e.toMap()).toList()),
    };
  }

  // Create from map for database operations
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toInt(),
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      estimatedMinutes: map['estimated_minutes']?.toInt() ?? 0,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      isSelectedForToday: (map['is_selected_for_today'] ?? 0) == 1,
      selectedDate: map['selected_date'] != null ? DateTime.parse(map['selected_date']) : null,
      steps: map['steps'] != null 
          ? (jsonDecode(map['steps']) as List).map((e) => TaskStep.fromMap(e)).toList() 
          : [],
    );
  }

  // Check if task is overdue
  bool get isOverdue {
    if (deadline == null) return false;
    return deadline!.isBefore(DateTime.now()) && 
           status != TaskStatus.completed && 
           status != TaskStatus.cancelled;
  }

  // Check if task is due today
  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
           deadline!.month == now.month &&
           deadline!.day == now.day;
  }

  // Check if task is selected for today
  bool get isSelectedForTodayAndDate {
    if (!isSelectedForToday || selectedDate == null) return false;
    final now = DateTime.now();
    return selectedDate!.year == now.year &&
           selectedDate!.month == now.month &&
           selectedDate!.day == now.day;
  }

  // Get priority color (for UI)
  String get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return '#4CAF50'; // Green
      case TaskPriority.medium:
        return '#FF9800'; // Orange
      case TaskPriority.high:
        return '#F44336'; // Red
      case TaskPriority.critical:
        return '#9C27B0'; // Purple
    }
  }

  // Get status color (for UI)
  String get statusColor {
    switch (status) {
      case TaskStatus.todo:
        return '#9E9E9E'; // Grey
      case TaskStatus.inProgress:
        return '#2196F3'; // Blue
      case TaskStatus.completed:
        return '#4CAF50'; // Green
      case TaskStatus.cancelled:
        return '#757575'; // Dark Grey
    }
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, status: $status, deadline: $deadline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.priority == priority &&
        other.deadline == deadline &&
        other.estimatedMinutes == estimatedMinutes &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSelectedForToday == isSelectedForToday &&
        other.selectedDate == selectedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      priority,
      deadline,
      estimatedMinutes,
      status,
      createdAt,
      updatedAt,
      isSelectedForToday,
      selectedDate,
    );
  }
}