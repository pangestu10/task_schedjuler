// lib/services/task_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart'; // For debugPrint
import '../core/api_config.dart';
import '../core/models/task.dart';
// Removed unused import: task_status.dart

class TaskService {
  final Dio _dio = Dio();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Helper to get headers with Auth Token
  Future<Options> _getAuthOptions() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final token = await user.getIdToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  // GET TASKS
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/getTasks',
        queryParameters: {
          'status': status,
          'priority': priority,
          'limit': limit,
          'offset': offset,
        },
        options: options,
      );

      if (response.data['success'] == true) {
        final List tasksJson = response.data['tasks'];
        return tasksJson.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load tasks');
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }

  // Shortcut for today
  Future<List<Task>> getTasksForToday(String userId) async {
    return getTasksForDate(userId, DateTime.now());
  }

  // Helper: Get tasks specific for a date
  Future<List<Task>> getTasksForDate(String userId, DateTime date) async {
    try {
      final allTasksHeader = await getTasks(limit: 100); 
      final targetDate = DateTime(date.year, date.month, date.day);
      
      return allTasksHeader.where((task) {
          final now = targetDate;
          if (task.isSelectedForToday && task.selectedDate != null) {
             final sd = task.selectedDate!;
             return sd.year == now.year && sd.month == now.month && sd.day == now.day;
          }
          if (task.deadline != null &&
              task.deadline!.year == now.year &&
              task.deadline!.month == now.month &&
              task.deadline!.day == now.day) {
            return true;
          }
          return false;
      }).toList();
    } catch (e) {
      debugPrint('Error getTasksForDate: $e');
      return [];
    }
  }
  
  Future<void> generateDailySnapshot(String userId) async {
    // Logic should handle by Backend, but we can call an endpoint if needed.
    // For now preventing it from crashing or doing nothing useful.
    try {
      final options = await _getAuthOptions();
      await _dio.post(
        '${ApiConfig.baseUrl}/generateDailySnapshot',
        data: {'userId': userId},
        options: options,
      );
    } catch (e) {
      debugPrint('Error generating daily snapshot (ignorable): $e');
    }
  }

  // CREATE TASK
  Future<Task> createTask(Task task) async {
    try {
      final options = await _getAuthOptions();
      final taskMap = task.toJson();
      // Remove fields that backend does not accept during creation
      taskMap.remove('id');
      taskMap.remove('status'); // Backend defaults to 'todo'
      taskMap.remove('ownerId'); // Backend calculates owner

      // NOTE: userId IS required by backend schema (it validates body.userId exists and matches token)
      
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/createTask',
        data: taskMap,
        options: options,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Task.fromJson(response.data['task']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create task');
      }
    } catch (e) {
      if (e is DioException) {
         debugPrint('Error creating task: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
         debugPrint('Error creating task: $e');
      }
      rethrow;
    }
  }

  // UPDATE TASK
  Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception('Task ID is required for update');
    try {
      final options = await _getAuthOptions();
      final data = task.toJson();
      data['taskId'] = task.id; // Add ID to body as potential fallback
      
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/updateTask',
        queryParameters: {'taskId': task.id},
        data: data,
        options: options,
      );

      if (response.data['success'] != true) {
         throw Exception(response.data['error'] ?? 'Failed to update task');
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      if (e is DioException) {
        debugPrint('Dio Error Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // DELETE TASK
  Future<void> deleteTask(String taskId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/deleteTask',
        queryParameters: {'taskId': taskId},
        options: options,
      );
      
      if (response.data['success'] != true) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // INVITE USER
  Future<void> inviteUser(String taskId, String email) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/inviteUserToTask',
        data: {
          'taskId': taskId,
          'email': email,
        },
        options: options,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Failed to invite user');
      }
      throw Exception('Failed to invite user: $e');
    }
  }

  // REMOVE COLLABORATOR
  Future<void> removeCollaborator(String taskId, String userIdToRemove) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/removeCollaborator',
        data: {
          'taskId': taskId,
          'userId': userIdToRemove,
        },
        options: options,
      );

       if (response.data['success'] != true) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      rethrow;
    }
  }

  // RESPOND TO INVITATION
  Future<void> respondToInvitation(String taskId, String responseAction) async {
    // responseAction: 'accept' or 'decline'
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/respondToInvitation',
        data: {
          'taskId': taskId,
          'response': responseAction,
        },
        options: options,
      );

       if (response.data['success'] != true) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Failed to respond to invitation');
      }
      rethrow;
    }
  }
  // GET PUBLIC USER PROFILE
  Future<Map<String, dynamic>> getPublicUserProfile(String userId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/getPublicUserProfile',
        queryParameters: {'userId': userId},
        options: options,
      );

      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['profile']);
      }
      return {'displayName': 'Unknown User', 'email': ''};
    } catch (e) {
      debugPrint('Error fetch user profile: $e');
      return {'displayName': 'Unknown', 'email': ''};
    }
  }
}