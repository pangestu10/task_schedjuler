import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/api_config.dart';
import '../core/models/timer_record.dart';
import '../core/models/daily_snapshot.dart';
import '../core/models/analytics_data.dart';
import './database_service.dart';

class AnalyticsService {
  final DatabaseService _dbService = DatabaseService();

  Future<AnalyticsData> calculateAnalytics(String userId) async {
    // Try cloud first, fallback to local
    try {
      return await fetchCloudAnalytics(userId);
    } catch (e) {
      print('Cloud analytics failed, falling back to local: $e');
      return _calculateLocalAnalytics(userId);
    }
  }

  Future<AnalyticsData> fetchCloudAnalytics(String userId) async {
    try {
      final dio = Dio();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final token = await user.getIdToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/getAnalyticsData',
        queryParameters: {'type': 'overview'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        final overview = response.data['analytics']['overview'];
        return AnalyticsData(
          dailyCompletionRate: (overview['completionRate'] as num).toDouble(),
          plannedVsActualDifference: 0,
          averageFocusDuration: (overview['totalFocusTime'] as num).toDouble() * 60,
          interruptionFrequency: 0,
          dominantWorkingHours: '09:00',
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch cloud analytics');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('Cloud Analytics Error Body: ${e.response?.data}');
        throw Exception(e.response?.data['error'] ?? 'Failed to fetch cloud analytics');
      }
      rethrow;
    }
  }

  Future<AnalyticsData> _calculateLocalAnalytics(String userId) async {
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
    try {
      return await getCloudWeeklyCompletion(userId);
    } catch (e) {
       print('Cloud weekly completion failed: $e');
       return _getLocalWeeklyCompletion(userId);
    }
  }

  Future<Map<String, double>> getCloudWeeklyCompletion(String userId) async {
    try {
      final dio = Dio();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final token = await user.getIdToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/getAnalyticsData',
        queryParameters: {'type': 'productivity'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        final dailyData = response.data['analytics']['dailyData'] as List;
        final Map<String, double> result = {};
        for (var entry in dailyData) {
          final completed = (entry['tasksCompleted'] as num).toDouble();
          final total = (entry['totalTaskCount'] as num).toDouble();
          
          final rate = total > 0 ? (completed / total) * 100 : 0.0;
          result[entry['date']] = rate;
        }
        return result;
      } else {
        throw Exception('Failed to fetch cloud weekly completion');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
         print('Weekly Completion Error Body: ${e.response?.data}');
      }
      throw Exception('Failed to fetch cloud weekly completion');
    }
  }

  Future<Map<String, double>> _getLocalWeeklyCompletion(String userId) async {
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

  Future<void> generateSnapshot(String userId) async {
    try {
      final dio = Dio();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();

      await dio.post(
        '${ApiConfig.baseUrl}/generateDailySnapshot',
        data: {'userId': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
         print('Generate Snapshot Error Body: ${e.response?.data}');
      }
      print('Error triggering backend snapshot: $e');
    }
  }

  Future<Map<String, int>> getSessionDistribution(String userId) async {
    try {
      return await getCloudSessionDistribution(userId);
    } catch (e) {
      print('Cloud session distribution failed: $e');
      return _getLocalSessionDistribution(userId);
    }
  }

  Future<Map<String, int>> getCloudSessionDistribution(String userId) async {
    try {
      final dio = Dio();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final token = await user.getIdToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/getAnalyticsData',
        queryParameters: {'type': 'timer'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        final byStopReason = response.data['analytics']['byStopReason'];
        return {
          'Completed': (byStopReason['completed'] as num).toInt(),
          'Interrupted': (byStopReason['interrupted'] as num).toInt(),
          'Lost Focus': (byStopReason['lostFocus'] as num).toInt(),
          'Break Taken': (byStopReason['take_a_break'] as num? ?? 0).toInt(),
          'Manual Stop': (byStopReason['manual'] as num).toInt(),
        };
      } else {
        throw Exception('Failed to fetch cloud session distribution');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('Session Distribution Error Body: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<Map<String, int>> _getLocalSessionDistribution(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final allRecords = await _dbService.getAllTimerRecords(userId);
    final recentRecords = allRecords.where((record) => 
        record.startTime.isAfter(thirtyDaysAgo)).toList();

    int completed = 0;
    int interrupted = 0;
    int lostFocus = 0;
    int breakTaken = 0;
    int manual = 0;

    for (var record in recentRecords) {
      switch (record.stopReason) {
        case 'completed':
          completed++;
          break;
        case 'interrupted':
          interrupted++;
          break;
        case 'lostFocus':
          lostFocus++;
          break;
        case 'take_a_break':
          breakTaken++;
          break;
        case 'manual':
          manual++;
          break;
      }
    }

    return {
      'Completed': completed,
      'Interrupted': interrupted,
      'Lost Focus': lostFocus,
      'Break Taken': breakTaken,
      'Manual Stop': manual,
    };
  }
}