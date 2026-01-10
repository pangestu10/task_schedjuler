// lib/services/task_service.dart
import '../core/models/task.dart';
import '../core/enums/task_status.dart';
import '../core/models/daily_snapshot.dart';
import './database_service.dart';

class TaskService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Task>> getTasksForToday(String userId) async {
    final allTasks = await _dbService.getUserTasks(userId);
    final today = DateTime.now();
    
    return allTasks.where((task) {
      // Tasks selected for today
      if (task.isSelectedForToday && 
          task.selectedDate != null &&
          task.selectedDate!.day == today.day &&
          task.selectedDate!.month == today.month &&
          task.selectedDate!.year == today.year) {
        return true;
      }
      
      // Tasks with deadline today
      if (task.deadline != null &&
          task.deadline!.day == today.day &&
          task.deadline!.month == today.month &&
          task.deadline!.year == today.year) {
        return true;
      }
      
      
      // Tasks currently active (within Start Date/Created Date and Deadline)
      if (task.deadline != null) {
         final startRaw = task.startDate ?? task.createdAt;
         final start = DateTime(startRaw.year, startRaw.month, startRaw.day);
         final end = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1)); // End of deadline day
         
         // Strictly: Start <= Today <= End
         if (today.compareTo(start) >= 0 && today.compareTo(end) <= 0) {
           return true;
         }
         
         // Fix for simple comparison
         if ((today.isAfter(start) || today.isAtSameMomentAs(start)) && 
             (today.isBefore(end) || today.isAtSameMomentAs(end))) {
           return true;
         }
      }
      
      // In-progress tasks from yesterday
      if (task.status == TaskStatus.inProgress &&
          (task.updatedAt?.day == today.day - 1 ||
           task.createdAt.day == today.day - 1)) {
        return true;
      }
      
      // Tasks worked on/completed today
      if ((task.status == TaskStatus.completed || task.status == TaskStatus.inProgress) &&
          task.updatedAt != null &&
          task.updatedAt!.day == today.day &&
          task.updatedAt!.month == today.month &&
          task.updatedAt!.year == today.year) {
        return true;
      }
      
      return false;
    }).toList();
  }

  Future<void> generateDailySnapshot(String userId) async {
    final tasks = await getTasksForToday(userId);
    final taskIds = tasks.where((t) => t.id != null).map((t) => t.id!).toList();
    final totalPlannedMinutes = tasks.fold(
        0, (sum, task) => sum + task.estimatedMinutes);
    
    // Calculate actual minutes from today
    final today = DateTime.now();
    final todayRecords = await _dbService.getTodayTimerRecords(userId, today);
    final totalActualMinutes = todayRecords.fold(
        0, (sum, record) => sum + (record.durationSeconds ~/ 60));
    
    final completedTaskCount = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    
    final snapshot = DailySnapshot(
      userId: userId,
      date: DateTime(today.year, today.month, today.day),
      taskIds: taskIds,
      totalPlannedMinutes: totalPlannedMinutes,
      totalActualMinutes: totalActualMinutes,
      completedTaskCount: completedTaskCount,
      totalTaskCount: tasks.length,
    );
    
    await _dbService.saveDailySnapshot(snapshot);
  }

  Future<List<Task>> getOverdueTasks(String userId) async {
    final allTasks = await _dbService.getUserTasks(userId);
    final now = DateTime.now();
    
    return allTasks.where((task) {
      return task.deadline != null &&
             task.deadline!.isBefore(now) &&
             task.status != TaskStatus.completed &&
             task.status != TaskStatus.cancelled;
    }).toList();
  }

  Future<List<Task>> getHighPriorityTasks(String userId) async {
    final allTasks = await _dbService.getUserTasks(userId);
    return allTasks
        .where((task) => 
            task.priority.index >= 2 && // high or critical
            task.status != TaskStatus.completed)
        .toList();
  }
}