// lib/providers/task_provider.dart
import 'package:flutter/foundation.dart';
import '../core/models/task.dart';
import '../core/enums/task_status.dart';
import '../services/task_service.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../core/constants/api_keys.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();
  
  TaskProvider() {
    _aiService.setApiKey(ApiKeys.groqApiKey);
  }
  
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  
  Future<void> loadUserTasks(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    _tasks = await _dbService.getUserTasks(userId);
    _todayTasks = await _taskService.getTasksForToday(userId);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addTask(Task task) async {
    final id = await _dbService.addTask(task);
    task.id = id;
    _tasks.insert(0, task);
    await _taskService.generateDailySnapshot(task.userId);
    notifyListeners();
  }
  
  Future<void> updateTask(Task task) async {
    await _dbService.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    await _taskService.generateDailySnapshot(task.userId);
    notifyListeners();
  }
  
  Future<void> deleteTask(int taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final userId = _tasks[taskIndex].userId;
      await _dbService.deleteTask(taskId);
      _tasks.removeAt(taskIndex);
      await _taskService.generateDailySnapshot(userId);
      notifyListeners();
    }
  }
  
  Future<void> markTaskComplete(int taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.completed;
    task.updatedAt = DateTime.now();
    await updateTask(task);
  }
  
  Future<void> selectTaskForToday(int taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.isSelectedForToday = true;
    task.selectedDate = DateTime.now();
    await updateTask(task);
    _todayTasks = await _taskService.getTasksForToday(task.userId);
    notifyListeners();
  }

  Future<List<String>> generateSteps(String title) async {
    return await _aiService.generateTaskSteps(title);
  }
}