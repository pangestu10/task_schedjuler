// lib/core/utils/notification_helper.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification type
    switch (response.payload) {
      case 'daily_alarm':
        // Navigate to daily task page
        break;
      case 'task_reminder':
        // Navigate to specific task
        break;
      case 'break_reminder':
        // Show break reminder
        break;
    }
  }

  // Show daily alarm notification
  static Future<void> showDailyAlarm() async {
    await _ensureInitialized();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.dailyAlarmChannelId,
      AppConstants.dailyAlarmChannelName,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      0,
      'Daily Tasks',
      'Time to plan your day! 📅',
      platformDetails,
      payload: 'daily_alarm',
    );
  }

  // Show task reminder notification
  static Future<void> showTaskReminder({
    required String taskTitle,
    required int taskId,
  }) async {
    await _ensureInitialized();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.taskReminderChannelId,
      AppConstants.taskReminderChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      taskId,
      'Task Reminder',
      'Don\'t forget: $taskTitle',
      platformDetails,
      payload: 'task_reminder',
    );
  }

  // Show break reminder notification
  static Future<void> showBreakReminder() async {
    await _ensureInitialized();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.taskReminderChannelId,
      AppConstants.taskReminderChannelName,
      importance: Importance.low,
      priority: Priority.low,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      999,
      'Break Time',
      'Time to take a short break! ☕',
      platformDetails,
      payload: 'break_reminder',
    );
  }

  // Show completion celebration notification
  static Future<void> showCompletionCelebration({
    required String taskTitle,
    required int completedTasks,
    required int totalTasks,
  }) async {
    await _ensureInitialized();
    
    final message = completedTasks == totalTasks
        ? 'All tasks completed! 🎉'
        : '$completedTasks of $totalTasks tasks completed';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.taskReminderChannelId,
      AppConstants.taskReminderChannelName,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      888,
      'Great job! ✨',
      '$taskTitle - $message',
      platformDetails,
    );
  }

  // Schedule notification for specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String payload = '',
  }) async {
    await _ensureInitialized();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.taskReminderChannelId,
      AppConstants.taskReminderChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true; // Assume enabled on iOS
  }

  // Ensure notifications are initialized
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    await _ensureInitialized();
    
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    
    return true; // iOS permissions handled during initialization
  }
}