// lib/services/analytics_service.dart
import '../core/models/timer_record.dart';
import '../core/models/daily_snapshot.dart';
import '../core/models/analytics_data.dart';
import './database_service.dart';

class AnalyticsService {
  final DatabaseService _dbService = DatabaseService();

  Future<AnalyticsData> calculateAnalytics(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // Get timer records for last 30 days
    final allRecords = await _dbService.getAllTimerRecords(userId);
    final recentRecords = allRecords.where((record) => 
        record.startTime.isAfter(thirtyDaysAgo)).toList();
    
    // Get daily snapshots
    final allSnapshots = await _dbService.getAllDailySnapshots(userId);
    final recentSnapshots = allSnapshots.where((snapshot) => 
        snapshot.date.isAfter(thirtyDaysAgo)).toList();
    
    // Calculate daily completion rate
    final totalDays = recentSnapshots.length;
    final completedDays = recentSnapshots.where((s) => 
        s.completedTaskCount > 0 && 
        s.completedTaskCount >= s.totalTaskCount / 2).length;
    final dailyCompletionRate = totalDays > 0 ? 
        (completedDays / totalDays) * 100 : 0;
    
    // Calculate planned vs actual
    int totalPlanned = 0;
    int totalActual = 0;
    for (var snapshot in recentSnapshots) {
      totalPlanned += snapshot.totalPlannedMinutes;
      totalActual += snapshot.totalActualMinutes;
    }
    final plannedVsActualDifference = totalPlanned - totalActual;
    
    // Calculate average focus duration
    final completedSessions = recentRecords.where(
        (r) => r.stopReason == 'completed').toList();
    final averageFocusDuration = completedSessions.isNotEmpty ?
        completedSessions.map((r) => r.durationSeconds)
            .reduce((a, b) => a + b) / completedSessions.length : 0;
    
    // Calculate interruption frequency
    final interruptions = recentRecords.where(
        (r) => r.stopReason == 'interrupted' || r.stopReason == 'lostFocus')
        .length;
    
    // Find dominant working hours
    final dominantHour = _findDominantHour(recentRecords);
    
    return AnalyticsData(
      dailyCompletionRate: dailyCompletionRate.toDouble(),
      plannedVsActualDifference: plannedVsActualDifference,
      averageFocusDuration: averageFocusDuration.toDouble(),
      interruptionFrequency: interruptions,
      dominantWorkingHours: '$dominantHour:00',
    );
  }
  
  int _findDominantHour(List<TimerRecord> records) {
    if (records.isEmpty) return 9; // Default to 9 AM
    
    final hourCounts = <int, int>{};
    for (var record in records) {
      final hour = record.startTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return 9;
    
    return hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Future<Map<String, double>> getWeeklyCompletion(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final allSnapshots = await _dbService.getAllDailySnapshots(userId);
    final weeklySnapshots = allSnapshots
        .where((snapshot) => snapshot.date.isAfter(weekAgo))
        .toList();
    
    final result = <String, double>{};
    
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final snapshot = weeklySnapshots.firstWhere(
        (s) => 
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day,
        orElse: () => DailySnapshot(
          userId: userId,
          date: date,
          taskIds: [],
          totalPlannedMinutes: 0,
          totalActualMinutes: 0,
          completedTaskCount: 0,
          totalTaskCount: 0,
        ),
      );
      
      final rate = snapshot.totalTaskCount > 0 ?
          (snapshot.completedTaskCount / snapshot.totalTaskCount) * 100 : 0;
      
      result[date.toString().split(' ')[0]] = rate.toDouble();
    }
    
    return result;
  }
}