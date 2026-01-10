// lib/core/models/routine_settings.dart
import '../constants/app_constants.dart';

class RoutineSettings {
  int? id;
  String userId;
  DateTime wakeTime;
  DateTime sleepTime;
  int dailyWorkTargetMinutes;
  DateTime updatedAt;

  RoutineSettings({
    this.id,
    required this.userId,
    required this.wakeTime,
    required this.sleepTime,
    this.dailyWorkTargetMinutes = AppConstants.defaultDailyWorkTarget,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // Create a copy with updated values
  RoutineSettings copyWith({
    int? id,
    String? userId,
    DateTime? wakeTime,
    DateTime? sleepTime,
    int? dailyWorkTargetMinutes,
    DateTime? updatedAt,
  }) {
    return RoutineSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      dailyWorkTargetMinutes: dailyWorkTargetMinutes ?? this.dailyWorkTargetMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'wake_time': _timeToString(wakeTime),
      'sleep_time': _timeToString(sleepTime),
      'daily_work_target_minutes': dailyWorkTargetMinutes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from map for database operations
  factory RoutineSettings.fromMap(Map<String, dynamic> map) {
    return RoutineSettings(
      id: map['id']?.toInt(),
      userId: map['user_id'] ?? '',
      wakeTime: _stringToTime(map['wake_time'] ?? '06:00'),
      sleepTime: _stringToTime(map['sleep_time'] ?? '22:00'),
      dailyWorkTargetMinutes: map['daily_work_target_minutes']?.toInt() ?? AppConstants.defaultDailyWorkTarget,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Convert DateTime to time string (HH:mm)
  static String _timeToString(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Convert time string (HH:mm) to DateTime
  static DateTime _stringToTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Get wake time as string
  String get wakeTimeString => _timeToString(wakeTime);

  // Get sleep time as string
  String get sleepTimeString => _timeToString(sleepTime);

  // Get daily work target in hours
  double get dailyWorkTargetHours => dailyWorkTargetMinutes / 60.0;

  // Get sleep duration in hours
  double get sleepDurationHours {
    var duration = sleepTime.difference(wakeTime);
    if (duration.isNegative) {
      duration = Duration(days: 1) - wakeTime.difference(sleepTime);
    }
    return duration.inMinutes / 60.0;
  }

  // Check if current time is within working hours
  bool get isWorkingHours {
    final now = DateTime.now();
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    if (wakeTime.isBefore(sleepTime)) {
      // Same day (e.g., 6:00 to 22:00)
      return currentTime.isAfter(wakeTime) && currentTime.isBefore(sleepTime);
    } else {
      // Overnight (e.g., 22:00 to 6:00)
      return currentTime.isAfter(wakeTime) || currentTime.isBefore(sleepTime);
    }
  }

  // Get working duration in hours
  double get workingDurationHours {
    var duration = sleepTime.difference(wakeTime);
    if (duration.isNegative) {
      duration = Duration(days: 1) - wakeTime.difference(sleepTime);
    }
    return duration.inMinutes / 60.0;
  }

  // Check if work target is realistic
  bool get isWorkTargetRealistic {
    return dailyWorkTargetMinutes <= (workingDurationHours * 60 * 0.8); // Max 80% of available time
  }

  // Get recommended break time based on work duration
  int get recommendedBreakMinutes {
    if (dailyWorkTargetMinutes <= 240) return 15; // 4 hours or less
    if (dailyWorkTargetMinutes <= 480) return 30; // 8 hours or less
    return 60; // More than 8 hours
  }

  @override
  String toString() {
    return 'RoutineSettings(id: $id, userId: $userId, wakeTime: $wakeTimeString, sleepTime: $sleepTimeString, dailyWorkTarget: $dailyWorkTargetMinutes min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineSettings &&
        other.id == id &&
        other.userId == userId &&
        other.wakeTime == wakeTime &&
        other.sleepTime == sleepTime &&
        other.dailyWorkTargetMinutes == dailyWorkTargetMinutes &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      wakeTime,
      sleepTime,
      dailyWorkTargetMinutes,
      updatedAt,
    );
  }
}