import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../core/models/notification_item.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final TaskService _taskService = TaskService();

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _notificationService.getNotifications();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // Optimistic update
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        userId: _notifications[index].userId,
        type: _notifications[index].type,
        title: _notifications[index].title,
        body: _notifications[index].body,
        data: _notifications[index].data,
        isRead: true, // Mark as read
        createdAt: _notifications[index].createdAt,
      );
      notifyListeners();
      
      await _notificationService.markAsRead(id);
    }
  }

  Future<void> acceptInvitation(String taskId, String notificationId) async {
    try {
      await _taskService.respondToInvitation(taskId, 'accept');
      // Delete notification after accepting
      await _notificationService.deleteNotification(notificationId);
      
      // Remove locally
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('No pending invitation') || e.toString().contains('Task not found')) {
         // Invitation is stale or invalid, remove notification anyway
         await _notificationService.deleteNotification(notificationId);
         _notifications.removeWhere((n) => n.id == notificationId);
         notifyListeners();
         return; // Treated as "handled" - or could rethrow if we want to show a toast
      }
      rethrow;
    }
  }

  Future<void> declineInvitation(String taskId, String notificationId) async {
    try {
      await _taskService.respondToInvitation(taskId, 'decline');
      // Delete notification after declining
      await _notificationService.deleteNotification(notificationId);

      // Remove locally
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('No pending invitation') || e.toString().contains('Task not found')) {
         // Invitation is stale or invalid, remove notification anyway
         await _notificationService.deleteNotification(notificationId);
         _notifications.removeWhere((n) => n.id == notificationId);
         notifyListeners();
         return;
      }
      rethrow;
    }
  }
}
