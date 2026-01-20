// lib/providers/task_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import '../core/models/task.dart';
import '../core/enums/task_status.dart';
import '../services/task_service.dart';
import '../services/ai_service.dart';
import '../core/constants/api_keys.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final AIService _aiService = AIService();
  
  // Note: DatabaseService removed/unused for Tasks to enforce Backend usage.
  
  TaskProvider() {
    _aiService.setApiKey(ApiKeys.groqApiKey);
  }
  
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  String? _error;
  
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load tasks from Backend
  Future<void> loadUserTasks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Fetch all tasks (with limit, maybe)
      _tasks = await _taskService.getTasks(limit: 100);
      
      // Filter for today locally or fetch
      _todayTasks = await _taskService.getTasksForToday(userId);
    } catch (e) {
      _error = e.toString();
      print("Error loading tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addTask(Task task) async {
    try {
      final createdTask = await _taskService.createTask(task);
      
      // Update All Tasks list with new reference
      _tasks = List.from(_tasks)..insert(0, createdTask);
      
      // Check if task belongs to today and update _todayTasks
      bool isToday = false;
      if (createdTask.selectedDate != null) {
        final now = DateTime.now();
        final sDate = createdTask.selectedDate!;
        if (sDate.year == now.year && sDate.month == now.month && sDate.day == now.day) {
          isToday = true;
        }
      }

      if (createdTask.isSelectedForToday || isToday) {
        _todayTasks = List.from(_todayTasks)..insert(0, createdTask);
      }
      
      notifyListeners();
    } catch (e) {
      print("Error adding task: $e");
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task);
      
      // Update in _tasks
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        // Create new list reference
        List<Task> newTasks = List.from(_tasks);
        newTasks[index] = task;
        _tasks = newTasks;
      }
      
      // Update in _todayTasks
      // Check if it should be in today's tasks
      bool isToday = false;
      if (task.selectedDate != null) {
        final now = DateTime.now();
        final sDate = task.selectedDate!;
        if (sDate.year == now.year && sDate.month == now.month && sDate.day == now.day) {
          isToday = true;
        }
      }

      // Logic: If it IS today/selected, add/update. If NOT, remove.
      final todayIndex = _todayTasks.indexWhere((t) => t.id == task.id);
      if (task.isSelectedForToday || isToday) {
         if (todayIndex != -1) {
            List<Task> newToday = List.from(_todayTasks);
            newToday[todayIndex] = task;
            _todayTasks = newToday;
         } else {
            _todayTasks = List.from(_todayTasks)..insert(0, task);
         }
      } else {
         if (todayIndex != -1) {
            _todayTasks = List.from(_todayTasks)..removeAt(todayIndex);
         }
      }
      
      notifyListeners();
    } catch (e) {
      print("Error updating task: $e");
      rethrow;
    }
  }
  
  // Changed taskId type to String
  Future<void> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      
      // Update both lists
      _tasks = List.from(_tasks)..removeWhere((t) => t.id == taskId);
      _todayTasks = List.from(_todayTasks)..removeWhere((t) => t.id == taskId);
      
      notifyListeners();
    } catch (e) {
      print("Error deleting task: $e");
      rethrow;
    }
  }
  
  // Changed taskId type to String
  Future<void> markTaskComplete(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.completed;
    task.updatedAt = DateTime.now();
    await updateTask(task);
  }
  
  // Changed taskId type to String
  Future<void> selectTaskForToday(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.isSelectedForToday = true;
    task.selectedDate = DateTime.now();
    await updateTask(task);
    if (!_todayTasks.any((t) => t.id == task.id)) {
      _todayTasks.add(task);
    }
    notifyListeners();
  }

  // Invite User
  Future<void> inviteUser(String taskId, String email) async {
    try {
      await _taskService.inviteUser(taskId, email);
    } catch (e) {
      rethrow;
    }
  }

  // Remove Collaborator
  Future<void> removeCollaborator(String taskId, String userId) async {
    try {
      await _taskService.removeCollaborator(taskId, userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> generateSteps(String title) async {
    return await _aiService.generateTaskSteps(title);
  }

  Future<Map<String, dynamic>> getCollaboratorInfo(String userId) async {
    return await _taskService.getPublicUserProfile(userId);
  }
}