// lib/core/constants/app_constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Daily Task Insight';
  static const String appVersion = '1.0.0';
  
  // Timer Settings
  static const int defaultPomodoroMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultDailyWorkTarget = 480; // 8 hours in minutes
  
  // Notification Settings
  static const String dailyAlarmChannelId = 'daily_alarm_channel';
  static const String dailyAlarmChannelName = 'Daily Alarm';
  static const String taskReminderChannelId = 'task_reminder_channel';
  static const String taskReminderChannelName = 'Task Reminders';
  
  // AI Service
  static const String aiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String aiModel = 'mixtral-8x7b-32768';
  
  // Analytics
  static const int analyticsDaysRange = 30;
  static const int weeklyAnalyticsDays = 7;
  
  // Time Formats
  static const String timeFormat = 'HH:mm';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Task Limits
  static const int maxDailyTasks = 20;
  static const int maxTaskTitleLength = 100;
  
  // Local Storage Keys
  static const String userIdKey = 'user_id';
  static const String routineSettingsKey = 'routine_settings';
  static const String aiApiKeyKey = 'ai_api_key';
  static const String notificationsEnabledKey = 'notifications_enabled';
}