import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/api_config.dart';
import '../core/models/notification_item.dart';

class NotificationService {
  final Dio _dio = Dio();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Options> _getAuthOptions() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final token = await user.getIdToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/getNotifications', // Ensure this endpoint exists or similar
        options: options,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['notifications'];
        return list.map((e) => NotificationItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception('Failed to fetch notifications: ${e.response!.data}');
      }
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post(
        '${ApiConfig.baseUrl}/markNotificationRead',
        data: {'notificationId': notificationId},
        options: options,
      );
    } catch (e) {
      // Ignore errors for mark read
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final options = await _getAuthOptions();
      await _dio.delete(
        '${ApiConfig.baseUrl}/deleteNotification',
        queryParameters: {'notificationId': notificationId},
        options: options,
      );
    } catch (e) {
      if (e is DioException) {
         throw Exception('Failed to delete notification: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to delete notification: $e');
    }
  }
}
