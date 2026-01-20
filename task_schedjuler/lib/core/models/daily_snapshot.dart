// lib/core/models/daily_snapshot.dart

class DailySnapshot {
  int? id;
  String userId;
  DateTime date;
  List<String> taskIds; // Changed from List<int> to List<String>
  int totalPlannedMinutes;
  int totalActualMinutes;
  int completedTaskCount;
  int totalTaskCount;

  DailySnapshot({
    this.id,
    required this.userId,
    required this.date,
    required this.taskIds,
    required this.totalPlannedMinutes,
    required this.totalActualMinutes,
    required this.completedTaskCount,
    required this.totalTaskCount,
  });

  // Create a copy with updated values
  DailySnapshot copyWith({
    int? id,
    String? userId,
    DateTime? date,
    List<String>? taskIds,
    int? totalPlannedMinutes,
    int? totalActualMinutes,
    int? completedTaskCount,
    int? totalTaskCount,
  }) {
    return DailySnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      taskIds: taskIds ?? this.taskIds,
      totalPlannedMinutes: totalPlannedMinutes ?? this.totalPlannedMinutes,
      totalActualMinutes: totalActualMinutes ?? this.totalActualMinutes,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      totalTaskCount: totalTaskCount ?? this.totalTaskCount,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'task_ids': taskIds.join(','),
      'total_planned_minutes': totalPlannedMinutes,
      'total_actual_minutes': totalActualMinutes,
      'completed_task_count': completedTaskCount,
      'total_task_count': totalTaskCount,
    };
  }

  // Create from map for database operations
  factory DailySnapshot.fromMap(Map<String, dynamic> map) {
    final taskIdsString = map['task_ids'] as String? ?? '';
    final taskIds = taskIdsString.isNotEmpty 
        ? taskIdsString.split(',').map((id) => id.trim()).toList()
        : <String>[];
    
    return DailySnapshot(
      id: map['id']?.toInt(),
      userId: map['user_id'] ?? '',
      date: DateTime.parse(map['date']),
      taskIds: taskIds,
      totalPlannedMinutes: map['total_planned_minutes']?.toInt() ?? 0,
      totalActualMinutes: map['total_actual_minutes']?.toInt() ?? 0,
      completedTaskCount: map['completed_task_count']?.toInt() ?? 0,
      totalTaskCount: map['total_task_count']?.toInt() ?? 0,
    );
  }

  // Get completion rate as percentage
  double get completionRate {
    if (totalTaskCount == 0) return 0.0;
    return (completedTaskCount / totalTaskCount) * 100.0;
  }

  // Get planned vs actual difference in minutes
  int get plannedVsActualDifference => totalPlannedMinutes - totalActualMinutes;

  // Get planned vs actual difference as percentage
  double get plannedVsActualPercentage {
    if (totalPlannedMinutes == 0) return 0.0;
    return ((totalActualMinutes - totalPlannedMinutes) / totalPlannedMinutes) * 100.0;
  }

  // Get planned hours
  double get plannedHours => totalPlannedMinutes / 60.0;

  // Get actual hours
  double get actualHours => totalActualMinutes / 60.0;

  // Check if day was productive (completed >= 50% of tasks)
  bool get isProductive => completionRate >= 50.0;

  // Check if day was very productive (completed >= 80% of tasks)
  bool get isVeryProductive => completionRate >= 80.0;

  // Check if goals were met (actual time >= 80% of planned time)
  bool get goalsMet => totalActualMinutes >= (totalPlannedMinutes * 0.8);

  // Get productivity score (0-100)
  double get productivityScore {
    double score = 0.0;
    
    // Task completion score (40% weight)
    score += (completionRate / 100.0) * 40.0;
    
    // Time adherence score (30% weight)
    final timeScore = totalPlannedMinutes > 0 
        ? (totalActualMinutes / totalPlannedMinutes).clamp(0.0, 1.5)
        : 0.0;
    score += (timeScore.clamp(0.0, 1.0)) * 30.0;
    
    // Consistency score (20% weight) - based on having tasks
    score += (totalTaskCount > 0 ? 1.0 : 0.0) * 20.0;
    
    // Efficiency score (10% weight) - completing tasks efficiently
    final efficiency = totalActualMinutes > 0 && completedTaskCount > 0
        ? (completedTaskCount / (totalActualMinutes / 60.0)).clamp(0.0, 2.0)
        : 0.0;
    score += (efficiency.clamp(0.0, 1.0)) * 10.0;
    
    return score.clamp(0.0, 100.0);
  }

  // Get performance rating
  String get performanceRating {
    final score = productivityScore;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  // Get performance emoji
  String get performanceEmoji {
    final score = productivityScore;
    if (score >= 90) return '🌟';
    if (score >= 75) return '😊';
    if (score >= 60) return '👍';
    if (score >= 40) return '😐';
    return '😔';
  }

  // Get formatted date string
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get day of week
  String get dayOfWeek {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // Check if snapshot is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if snapshot is for yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  @override
  String toString() {
    return 'DailySnapshot(id: $id, date: $formattedDate, completion: ${completionRate.toStringAsFixed(1)}%, productivity: ${productivityScore.toStringAsFixed(1)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailySnapshot &&
        other.id == id &&
        other.userId == userId &&
        other.date == date &&
        other.taskIds.toString() == taskIds.toString() &&
        other.totalPlannedMinutes == totalPlannedMinutes &&
        other.totalActualMinutes == totalActualMinutes &&
        other.completedTaskCount == completedTaskCount &&
        other.totalTaskCount == totalTaskCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      date,
      taskIds,
      totalPlannedMinutes,
      totalActualMinutes,
      completedTaskCount,
      totalTaskCount,
    );
  }
}