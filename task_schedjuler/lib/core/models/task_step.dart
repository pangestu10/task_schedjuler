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
      'completed': isCompleted, // Backend expects 'completed' (boolean), not 'is_completed'
      // 'durationSeconds' is not in backend defaults schema, but okay to send if backend ignores excessive fields in subarray?
      // Backend schema for steps: id, title, completed. It does NOT allow other fields without 'unknown(true)' or similar?
      // Wait, backend 'createTaskSchema`: steps: Joi.array().items(Joi.object({...}).required())
      // It might reject unknown fields. Safest to omit durationSeconds for now or check backend.
    };
  }

  factory TaskStep.fromMap(Map<String, dynamic> map) {
    return TaskStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['completed'] == true || map['is_completed'] == 1 || map['isCompleted'] == true,
      durationSeconds: map['duration_seconds'] ?? 0,
    );
  }
}

