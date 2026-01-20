import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/navigator_key.dart';
import 'task_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      debugPrint('Alarm Service: Initializing timezones...');
      tz_data.initializeTimeZones();
      debugPrint('Alarm Service: Timezones initialized.');
      // Use dynamic to avoid compile-time type mismatch since library might return String or TimezoneInfo
      final dynamic timeZone = await FlutterTimezone.getLocalTimezone();
      
      String? timeZoneName;
      if (timeZone is String) {
        timeZoneName = timeZone;
      } else if (timeZone != null) {
        // Try all known properties across different library versions
        try { timeZoneName = (timeZone as dynamic).identifier; } catch (_) {}
        try { timeZoneName ??= (timeZone as dynamic).timezone; } catch (_) {}
        try { timeZoneName ??= (timeZone as dynamic).id; } catch (_) {}
        try { timeZoneName ??= (timeZone as dynamic).name; } catch (_) {}
        
        // Fallback to toString() if it doesn't look like a generic object description
        final String ts = timeZone.toString();
        if (timeZoneName == null || (timeZoneName.contains('Instance of') && !ts.contains('Instance of'))) {
          // Some versions return the ID in toString()
          if (!ts.contains('Instance of')) {
            timeZoneName = ts;
          }
        }
      }
      
      // Smart Fallback for Indonesia if detection fails (since user is at UTC+7)
      if (timeZoneName == null || timeZoneName.contains('Instance of')) {
        debugPrint('Alarm Service: Timezone detection returned invalid result, trying Asia/Jakarta fallback');
        timeZoneName = 'Asia/Jakarta';
      }
      
      if (!timeZoneName.contains('Instance of')) {
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          debugPrint('Alarm Service: Local timezone set to $timeZoneName');
        } catch (e) {
          debugPrint('Alarm Service: Invalid timezone ID $timeZoneName, falling back to UTC');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      } else {
        debugPrint('Alarm Service: Could not determine local timezone, falling back to UTC');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Alarm Service: Critical failure in timezone initialization: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('Alarm Service: Notification tapped with payload: ${response.payload}');
          // Fix: Navigate to root '/' instead of '/tasks' to keep BottomNavigationBar (MainApp)
          String routeName = response.payload!;
          if (routeName == '/tasks') {
            routeName = '/';
          }
          navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (route) => false);
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_alarm_channel_v5', // v5 for clean start
      'Daily Notification',
      description: 'Notifikasi harian untuk tugas Anda',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('Alarm Service: Android channel created successfully');
    } catch (e) {
      debugPrint('Alarm Service: Failed to create Android channel: $e');
    }
  }

  static Future<DateTime> setDailyAlarm(DateTime wakeTime, {required String userId}) async {
    await cancelAllAlarms();
    
    // Use tzNow to be 100% sure we are relative to the library's internal clock
    final tzNow = tz.TZDateTime.now(tz.local);
    var tzScheduledDate = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      wakeTime.hour,
      wakeTime.minute,
    );
    
    // If that time has already passed TODAY, we schedule for TOMORROW.
    if (tzScheduledDate.isBefore(tzNow)) {
      tzScheduledDate = tzScheduledDate.add(const Duration(days: 1));
    }
    
    debugPrint('Alarm Service: Current TZ Time is $tzNow');
    debugPrint('Alarm Service: Scheduling Daily Alarm for $tzScheduledDate');
    
    // Fetch tasks for the scheduled date to populate notification content
    String notificationBody = 'Waktunya bangun! Cek rencana harimu di Task Schedjuler.';
    try {
      final taskService = TaskService();
      // We need to convert TZDateTime back to DateTime for the service
      final dateForTasks = DateTime(
        tzScheduledDate.year, 
        tzScheduledDate.month, 
        tzScheduledDate.day
      );
      
      final tasks = await taskService.getTasksForDate(userId, dateForTasks);
      
      if (tasks.isNotEmpty) {
        final topTasks = tasks.take(3).map((t) => '• ${t.title}').join('\n');
        notificationBody = 'Rencana Hari Ini (${tasks.length} Tugas):\n$topTasks';
        if (tasks.length > 3) {
          notificationBody += '\n...dan ${tasks.length - 3} lainnya.';
        }
      } else {
         notificationBody = 'Belum ada tugas hari ini. Yuk rencanakan sekarang! 📝';
      }
    } catch (e) {
      debugPrint('Alarm Service: Failed to fetch tasks for notification: $e');
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_alarm_channel_v5',
      'Daily Notification',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Task Schedjuler',
      playSound: true,
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
    
    
    try {
      final bool hasExactPermission = await checkExactAlarmPermission();
      final androidScheduleMode = hasExactPermission 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notificationsPlugin.zonedSchedule(
        0,
        'Selamat Pagi! 🌄',
        notificationBody,
        tzScheduledDate,
        platformDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/',
      );
      debugPrint('Alarm Service: Notification scheduled (${hasExactPermission ? "Exact" : "Inexact"}) for $tzScheduledDate');
    } catch (e) {
      debugPrint('Alarm Service: Failed to schedule notification: $e');
    }
    
    return DateTime(tzScheduledDate.year, tzScheduledDate.month, tzScheduledDate.day, tzScheduledDate.hour, tzScheduledDate.minute);
  }

  static Future<void> testAlarm() async {
    final tzNow = tz.TZDateTime.now(tz.local);
    final tzTestDate = tzNow.add(const Duration(seconds: 5)); // 5 seconds is enough
    
    debugPrint('Alarm Service: Current TZ Time: $tzNow');
    debugPrint('Alarm Service: Scheduling TEST for $tzTestDate');
    
    // Check if we can schedule exact alarms
    final bool canSchedule = await Permission.scheduleExactAlarm.status.isGranted;
    debugPrint('Alarm Service: Can schedule exact?: $canSchedule');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_alarm_channel_v5',
      'Diagnostic Test',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Task Schedjuler',
      playSound: true,
      enableVibration: true,
      // fullScreenIntent: true, // REMOVED: Causing issues on some Android 14+ devices without special permission
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    final int testId = DateTime.now().millisecond + 3000;
    
    try {
      debugPrint('Alarm Service: Attempting Exact Schedule...');
      await _notificationsPlugin.zonedSchedule(
        testId,
        'Jadwal Berhasil! 🎉',
        'Notifikasi muncul TEPAT WAKTU (5 detik). ID: $testId',
        tzTestDate,
        platformDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '/',
      );
      debugPrint('Alarm Service: TEST Scheduled (Exact) with ID $testId');
    } catch (e) {
      debugPrint('Alarm Service: TEST failed (Exact): $e. Trying Inexact fallback...');
      // Fallback to inexact ONLY if exact fails
      await _notificationsPlugin.zonedSchedule(
        testId,
        'Jadwal Berhasil (Inexact)! ⏳',
        'Exact gagal, ini muncul via Inexact. Mungkin telat beberapa menit.',
        tzTestDate,
        platformDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/',
      );
      debugPrint('Alarm Service: TEST Scheduled (Inexact) with ID $testId');
    }
  }

  static Future<void> checkBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      debugPrint('Permission: Battery Optimization status: $status');
      if (status.isDenied || status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Permission: Error checking battery: $e');
    }
  }

  static Future<bool> checkExactAlarmPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.scheduleExactAlarm.status;
        debugPrint('Alarm Service: Exact Alarm permission status: $status');
        
        if (!status.isGranted) {
           final result = await Permission.scheduleExactAlarm.request();
           return result.isGranted;
        }
        return true;
      }
      return true; 
    } catch (e) {
      debugPrint('Alarm Service: Error checking exact alarm permission: $e');
      return false;
    }
  }

  static String get debugTimezone => tz.local.name;

  static Future<void> showInstantNotification() async {
    debugPrint('Alarm Service: Showing Instant Notification');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_alarm_channel_v5',
      'Instant Notification',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Instant',
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationsPlugin.show(
      888,
      'Test Langsung 🚀',
      'Jika Anda melihat ini, berarti notifikasi dasar BERHASIL.',
      platformDetails,
      payload: '/',
    );
  }

  static Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }
}