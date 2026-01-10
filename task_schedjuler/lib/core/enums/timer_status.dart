// lib/core/enums/timer_status.dart
enum TimerStatus {
  idle,
  stopped,
  running,
  paused,
  completed;

  // Get display name
  String get displayName {
    switch (this) {
      case TimerStatus.idle:
        return 'Idle';
      case TimerStatus.stopped:
        return 'Stopped';
      case TimerStatus.running:
        return 'Running';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.completed:
        return 'Completed';
    }
  }

  // Get numeric value for sorting
  int get value {
    switch (this) {
      case TimerStatus.idle:
        return 0;
      case TimerStatus.stopped:
        return 1;
      case TimerStatus.running:
        return 2;
      case TimerStatus.paused:
        return 3;
      case TimerStatus.completed:
        return 4;
    }
  }

  // Get emoji representation
  String get emoji {
    switch (this) {
      case TimerStatus.idle:
        return '💤';
      case TimerStatus.stopped:
        return '⏹️';
      case TimerStatus.running:
        return '▶️';
      case TimerStatus.paused:
        return '⏸️';
      case TimerStatus.completed:
        return '✅';
    }
  }

  // Get color hex code
  String get colorHex {
    switch (this) {
      case TimerStatus.idle:
        return '#BDBDBD';
      case TimerStatus.stopped:
        return '#9E9E9E';
      case TimerStatus.running:
        return '#4CAF50';
      case TimerStatus.paused:
        return '#FF9800';
      case TimerStatus.completed:
        return '#2196F3';
    }
  }

  // Check if timer is active (running or paused)
  bool get isActive => this == TimerStatus.running || this == TimerStatus.paused;

  // Check if timer can be started
  bool get canStart => this == TimerStatus.idle || this == TimerStatus.stopped || this == TimerStatus.completed;

  // Check if timer can be paused
  bool get canPause => this == TimerStatus.running;

  // Check if timer can be resumed
  bool get canResume => this == TimerStatus.paused;

  // Check if timer can be stopped
  bool get canStop => this == TimerStatus.running || this == TimerStatus.paused;
}