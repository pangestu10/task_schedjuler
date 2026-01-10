// lib/core/models/timer_record.dart

class TimerRecord {
  int? id;
  String userId;
  int? taskId;
  DateTime startTime;
  DateTime? endTime;
  int durationSeconds;
  String stopReason;

  TimerRecord({
    this.id,
    required this.userId,
    this.taskId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.stopReason,
  });

  // Create a copy with updated values
  TimerRecord copyWith({
    int? id,
    String? userId,
    int? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? stopReason,
  }) {
    return TimerRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      stopReason: stopReason ?? this.stopReason,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'stop_reason': stopReason,
    };
  }

  // Create from map for database operations
  factory TimerRecord.fromMap(Map<String, dynamic> map) {
    return TimerRecord(
      id: map['id']?.toInt(),
      userId: map['user_id'] ?? '',
      taskId: map['task_id']?.toInt(),
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      durationSeconds: map['duration_seconds']?.toInt() ?? 0,
      stopReason: map['stop_reason'] ?? '',
    );
  }

  // Get duration in minutes
  double get durationMinutes => durationSeconds / 60.0;

  // Get duration in hours
  double get durationHours => durationSeconds / 3600.0;

  // Get formatted duration string
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get short formatted duration (mm:ss or hh:mm)
  String get shortFormattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Check if timer is currently running
  bool get isRunning => endTime == null;

  // Check if timer was completed successfully
  bool get isCompleted => stopReason == 'completed';

  // Check if timer was stopped due to interruption
  bool get wasInterrupted => stopReason == 'interrupted' || stopReason == 'lostFocus';

  // Check if timer has associated task
  bool get hasTask => taskId != null;

  // Get stop reason display name
  String get stopReasonDisplayName {
    switch (stopReason) {
      case 'completed':
        return 'Completed';
      case 'interrupted':
        return 'Interrupted';
      case 'lostFocus':
        return 'Lost Focus';
      case 'manual':
        return 'Manual Stop';
      case 'running':
        return 'Running';
      default:
        return 'Unknown';
    }
  }

  // Get stop reason emoji
  String get stopReasonEmoji {
    switch (stopReason) {
      case 'completed':
        return '✅';
      case 'interrupted':
        return '⏸️';
      case 'lostFocus':
        return '🔄';
      case 'manual':
        return '⏹️';
      case 'running':
        return '▶️';
      default:
        return '❓';
    }
  }

  // Get productivity score (0-100 based on completion and duration)
  double get productivityScore {
    if (!isCompleted) return durationSeconds > 0 ? 30.0 : 0.0; // Partial credit for effort
    
    // Base score for completion
    double score = 80.0;
    
    // Bonus for longer sessions (up to 20 points)
    final durationBonus = (durationSeconds / 3600.0) * 20.0; // 20 points per hour
    score += durationBonus.clamp(0.0, 20.0);
    
    return score.clamp(0.0, 100.0);
  }

  @override
  String toString() {
    return 'TimerRecord(id: $id, userId: $userId, taskId: $taskId, duration: $formattedDuration, reason: $stopReason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerRecord &&
        other.id == id &&
        other.userId == userId &&
        other.taskId == taskId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.durationSeconds == durationSeconds &&
        other.stopReason == stopReason;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      taskId,
      startTime,
      endTime,
      durationSeconds,
      stopReason,
    );
  }
}