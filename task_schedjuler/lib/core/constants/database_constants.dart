// lib/core/constants/database_constants.dart
class DatabaseConstants {
  // Database Info
  static const String databaseName = 'daily_task_insight.db';
  static const int databaseVersion = 1;
  
  // Table Names
  static const String tasksTable = 'tasks';
  static const String routineSettingsTable = 'routine_settings';
  static const String timerRecordsTable = 'timer_records';
  static const String dailySnapshotsTable = 'daily_snapshots';
  
  // Tasks Table Columns
  static const String taskIdColumn = 'id';
  static const String taskUserIdColumn = 'user_id';
  static const String taskTitleColumn = 'title';
  static const String taskPriorityColumn = 'priority';
  static const String taskDeadlineColumn = 'deadline';
  static const String taskEstimatedMinutesColumn = 'estimated_minutes';
  static const String taskStatusColumn = 'status';
  static const String taskCreatedAtColumn = 'created_at';
  static const String taskUpdatedAtColumn = 'updated_at';
  static const String taskIsSelectedForTodayColumn = 'is_selected_for_today';
  static const String taskSelectedDateColumn = 'selected_date';
  
  // Routine Settings Table Columns
  static const String routineIdColumn = 'id';
  static const String routineUserIdColumn = 'user_id';
  static const String routineWakeTimeColumn = 'wake_time';
  static const String routineSleepTimeColumn = 'sleep_time';
  static const String routineDailyWorkTargetColumn = 'daily_work_target_minutes';
  static const String routineUpdatedAtColumn = 'updated_at';
  
  // Timer Records Table Columns
  static const String timerIdColumn = 'id';
  static const String timerUserIdColumn = 'user_id';
  static const String timerTaskIdColumn = 'task_id';
  static const String timerStartTimeColumn = 'start_time';
  static const String timerEndTimeColumn = 'end_time';
  static const String timerDurationSecondsColumn = 'duration_seconds';
  static const String timerStopReasonColumn = 'stop_reason';
  
  // Daily Snapshots Table Columns
  static const String snapshotIdColumn = 'id';
  static const String snapshotUserIdColumn = 'user_id';
  static const String snapshotDateColumn = 'date';
  static const String snapshotTaskIdsColumn = 'task_ids';
  static const String snapshotTotalPlannedMinutesColumn = 'total_planned_minutes';
  static const String snapshotTotalActualMinutesColumn = 'total_actual_minutes';
  static const String snapshotCompletedTaskCountColumn = 'completed_task_count';
  static const String snapshotTotalTaskCountColumn = 'total_task_count';
  
  // Index Names
  static const String tasksUserIdIndex = 'idx_tasks_user_id';
  static const String tasksCreatedAtIndex = 'idx_tasks_created_at';
  static const String timerRecordsUserIdIndex = 'idx_timer_records_user_id';
  static const String timerRecordsStartTimeIndex = 'idx_timer_records_start_time';
  static const String dailySnapshotsUserIdIndex = 'idx_daily_snapshots_user_id';
  
  // Create Table Queries
  static const String createTasksTable = '''
    CREATE TABLE $tasksTable (
      $taskIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $taskUserIdColumn TEXT NOT NULL,
      $taskTitleColumn TEXT NOT NULL,
      $taskPriorityColumn TEXT NOT NULL,
      $taskDeadlineColumn TEXT,
      $taskEstimatedMinutesColumn INTEGER NOT NULL,
      $taskStatusColumn TEXT NOT NULL,
      $taskCreatedAtColumn TEXT NOT NULL,
      $taskUpdatedAtColumn TEXT,
      $taskIsSelectedForTodayColumn INTEGER NOT NULL DEFAULT 0,
      $taskSelectedDateColumn TEXT
    )
  ''';
  
  static const String createRoutineSettingsTable = '''
    CREATE TABLE $routineSettingsTable (
      $routineIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $routineUserIdColumn TEXT NOT NULL UNIQUE,
      $routineWakeTimeColumn TEXT NOT NULL,
      $routineSleepTimeColumn TEXT NOT NULL,
      $routineDailyWorkTargetColumn INTEGER NOT NULL,
      $routineUpdatedAtColumn TEXT NOT NULL
    )
  ''';
  
  static const String createTimerRecordsTable = '''
    CREATE TABLE $timerRecordsTable (
      $timerIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $timerUserIdColumn TEXT NOT NULL,
      $timerTaskIdColumn INTEGER,
      $timerStartTimeColumn TEXT NOT NULL,
      $timerEndTimeColumn TEXT,
      $timerDurationSecondsColumn INTEGER NOT NULL,
      $timerStopReasonColumn TEXT NOT NULL
    )
  ''';
  
  static const String createDailySnapshotsTable = '''
    CREATE TABLE $dailySnapshotsTable (
      $snapshotIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $snapshotUserIdColumn TEXT NOT NULL,
      $snapshotDateColumn TEXT NOT NULL,
      $snapshotTaskIdsColumn TEXT NOT NULL,
      $snapshotTotalPlannedMinutesColumn INTEGER NOT NULL,
      $snapshotTotalActualMinutesColumn INTEGER NOT NULL,
      $snapshotCompletedTaskCountColumn INTEGER NOT NULL,
      $snapshotTotalTaskCountColumn INTEGER NOT NULL,
      UNIQUE($snapshotUserIdColumn, $snapshotDateColumn)
    )
  ''';
  
  // Create Index Queries
  static const String createTasksUserIdIndex = '''
    CREATE INDEX $tasksUserIdIndex ON $tasksTable($taskUserIdColumn)
  ''';
  
  static const String createTasksCreatedAtIndex = '''
    CREATE INDEX $tasksCreatedAtIndex ON $tasksTable($taskCreatedAtColumn)
  ''';
  
  static const String createTimerRecordsUserIdIndex = '''
    CREATE INDEX $timerRecordsUserIdIndex ON $timerRecordsTable($timerUserIdColumn)
  ''';
  
  static const String createTimerRecordsStartTimeIndex = '''
    CREATE INDEX $timerRecordsStartTimeIndex ON $timerRecordsTable($timerStartTimeColumn)
  ''';
  
  static const String createDailySnapshotsUserIdIndex = '''
    CREATE INDEX $dailySnapshotsUserIdIndex ON $dailySnapshotsTable($snapshotUserIdColumn)
  ''';
}