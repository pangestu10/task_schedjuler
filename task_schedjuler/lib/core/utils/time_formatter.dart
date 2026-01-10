// lib/core/utils/time_formatter.dart
class TimeFormatter {
  // Format duration in seconds to human readable string
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  // Format duration in seconds to short string (mm:ss or hh:mm)
  static String formatDurationShort(int seconds) {
    if (seconds <= 0) return '00:00';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Format duration in seconds to compact string
  static String formatDurationCompact(int seconds) {
    if (seconds <= 0) return '0m';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Format minutes to human readable string
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  // Format DateTime to time string (HH:mm)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Format DateTime to date string (yyyy-MM-dd)
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format DateTime to date and time string
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  // Format DateTime to relative time string
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Format DateTime to day name
  static String formatDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // Format DateTime to full day name
  static String formatFullDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // Format DateTime to month name
  static String formatMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  // Format DateTime to full month name
  static String formatFullMonthName(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[date.month - 1];
  }

  // Format DateTime to short date string (MMM dd)
  static String formatShortDate(DateTime date) {
    return '${formatMonthName(date)} ${date.day.toString().padLeft(2, '0')}';
  }

  // Format DateTime to medium date string (MMM dd, yyyy)
  static String formatMediumDate(DateTime date) {
    return '${formatMonthName(date)} ${date.day}, ${date.year}';
  }

  // Format DateTime to long date string (MMMM dd, yyyy)
  static String formatLongDate(DateTime date) {
    return '${formatFullMonthName(date)} ${date.day}, ${date.year}';
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Format date with relative context
  static String formatDateWithContext(DateTime date) {
    if (isToday(date)) {
      return 'Today, ${formatTime(date)}';
    } else if (isYesterday(date)) {
      return 'Yesterday, ${formatTime(date)}';
    } else if (isTomorrow(date)) {
      return 'Tomorrow, ${formatTime(date)}';
    } else if (isThisWeek(date)) {
      return '${formatDayName(date)}, ${formatTime(date)}';
    } else {
      return '${formatMediumDate(date)}, ${formatTime(date)}';
    }
  }

  // Convert time string (HH:mm) to DateTime
  static DateTime parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Convert seconds to hours and minutes
  static Map<String, int> secondsToHoursMinutes(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    return {
      'hours': hours,
      'minutes': minutes,
    };
  }

  // Convert minutes to hours and minutes
  static Map<String, int> minutesToHoursMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    return {
      'hours': hours,
      'minutes': mins,
    };
  }

  // Calculate duration between two DateTimes in seconds
  static int durationInSeconds(DateTime start, DateTime end) {
    return end.difference(start).inSeconds;
  }

  // Calculate duration between two DateTimes in minutes
  static int durationInMinutes(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToAdd = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day + daysToAdd);
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  // Check if time is between two times
  static bool isTimeBetween(
    DateTime time,
    DateTime startTime,
    DateTime endTime,
  ) {
    final timeOnly = DateTime(0, 0, 0, time.hour, time.minute);
    final startOnly = DateTime(0, 0, 0, startTime.hour, startTime.minute);
    final endOnly = DateTime(0, 0, 0, endTime.hour, endTime.minute);
    
    if (startOnly.isBefore(endOnly)) {
      // Same day range
      return timeOnly.isAfter(startOnly) && timeOnly.isBefore(endOnly);
    } else {
      // Overnight range
      return timeOnly.isAfter(startOnly) || timeOnly.isBefore(endOnly);
    }
  }

  // Format duration for timer display
  static String formatTimerDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}