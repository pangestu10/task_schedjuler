// lib/core/enums/task_status.dart
enum TaskStatus {
  todo,
  inProgress,
  completed,
  cancelled;

  // Get display name
  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get numeric value for sorting
  int get value {
    switch (this) {
      case TaskStatus.todo:
        return 0;
      case TaskStatus.inProgress:
        return 1;
      case TaskStatus.completed:
        return 2;
      case TaskStatus.cancelled:
        return 3;
    }
  }

  // Get emoji representation
  String get emoji {
    switch (this) {
      case TaskStatus.todo:
        return '📝';
      case TaskStatus.inProgress:
        return '⏳';
      case TaskStatus.completed:
        return '✅';
      case TaskStatus.cancelled:
        return '❌';
    }
  }

  // Get color hex code
  String get colorHex {
    switch (this) {
      case TaskStatus.todo:
        return '#9E9E9E';
      case TaskStatus.inProgress:
        return '#2196F3';
      case TaskStatus.completed:
        return '#4CAF50';
      case TaskStatus.cancelled:
        return '#757575';
    }
  }

  // Check if task is active (not completed or cancelled)
  bool get isActive => this == TaskStatus.todo || this == TaskStatus.inProgress;

  // Check if task is finished (completed or cancelled)
  bool get isFinished => this == TaskStatus.completed || this == TaskStatus.cancelled;
}