// lib/core/models/task_step.dart
class TaskStep {
  String id;
  String title;
  bool isCompleted;
  int durationSeconds;

  TaskStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'duration_seconds': durationSeconds,
    };
  }

  factory TaskStep.fromMap(Map<String, dynamic> map) {
    return TaskStep(
      id: map['id'],
      title: map['title'],
      isCompleted: map['is_completed'] == 1,
      durationSeconds: map['duration_seconds'] ?? 0,
    );
  }
}
