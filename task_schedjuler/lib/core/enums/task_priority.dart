// lib/core/enums/task_priority.dart
enum TaskPriority {
  low,
  medium,
  high,
  critical;

  // Get display name
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  // Get numeric value for sorting
  int get value {
    switch (this) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.critical:
        return 3;
    }
  }

  // Get emoji representation
  String get emoji {
    switch (this) {
      case TaskPriority.low:
        return '🟢';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.high:
        return '🟠';
      case TaskPriority.critical:
        return '🔴';
    }
  }

  // Get color hex code
  String get colorHex {
    switch (this) {
      case TaskPriority.low:
        return '#4CAF50';
      case TaskPriority.medium:
        return '#FF9800';
      case TaskPriority.high:
        return '#F44336';
      case TaskPriority.critical:
        return '#9C27B0';
    }
  }
}