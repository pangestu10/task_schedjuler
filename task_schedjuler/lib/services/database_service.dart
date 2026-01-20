// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/models/task.dart';
import '../core/models/routine_settings.dart';
import '../core/models/timer_record.dart';
import '../core/models/daily_snapshot.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'daily_task_insight.db');

    return await openDatabase(
      databasePath,
      version: 4, // Bumped to 4 for schema change (Task IDs -> String)
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN steps TEXT');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN start_date TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 4) {
      // Major schema change: IDs are now Strings.
      // Easiest path: recreate tables. WARNING: This wipes local data.
      // Since assuming move to backend, this is acceptable for cache tables.
      // Ideally we'd migrate, but SQLite types are flexible.
      
      // We essentially want `timer_records.task_id` to be TEXT.
      // SQLite doesn't support changing column type easily.
      // We will perform a drop and recreate for affected tables if acceptable.
      // Or just continue, as SQLite allows storing text in INTEGER columns (Type Affinity),
      // BUT `tasks.id` was INTEGER PRIMARY KEY AUTOINCREMENT. This MUST change if we were to store UUIDs.
      
      // Let's drop and recreate tasks and timer_records
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS timer_records');
      
      // Re-run create for these
      await _createTasksTable(db);
      await _createTimerRecordsTable(db);
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await _createTasksTable(db);
    
    // Routine settings table (Keep as is)
    await db.execute('''
      CREATE TABLE routine_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        wake_time TEXT NOT NULL,
        sleep_time TEXT NOT NULL,
        daily_work_target_minutes INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createTimerRecordsTable(db);

    // Daily snapshots table
    await db.execute('''
      CREATE TABLE daily_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        task_ids TEXT NOT NULL,
        total_planned_minutes INTEGER NOT NULL,
        total_actual_minutes INTEGER NOT NULL,
        completed_task_count INTEGER NOT NULL,
        total_task_count INTEGER NOT NULL,
        UNIQUE(user_id, date)
      )
    ''');

    await db.execute('CREATE INDEX idx_daily_snapshots_user_id ON daily_snapshots(user_id)');
  }
  
  Future<void> _createTasksTable(Database db) async {
    // Tasks table - ID is now TEXT to match Backend UUID
    // Note: If we use Backend, we don't necessarily NEED this table unless caching.
    // Specifying it as TEXT PRIMARY KEY removes AUTOINCREMENT.
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY, 
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        priority TEXT NOT NULL,
        deadline TEXT,
        start_date TEXT,
        estimated_minutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_selected_for_today INTEGER NOT NULL DEFAULT 0,
        selected_date TEXT,
        steps TEXT,
        collaborators TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_tasks_created_at ON tasks(created_at)');
  }
  
  Future<void> _createTimerRecordsTable(Database db) async {
    // Timer records table - task_id is now TEXT
    await db.execute('''
      CREATE TABLE timer_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        task_id TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER NOT NULL,
        stop_reason TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_timer_records_user_id ON timer_records(user_id)');
    await db.execute('CREATE INDEX idx_timer_records_start_time ON timer_records(start_time)');
  }

  // Task operations - UPDATED for String ID
  // Note: These methods update LOCAL DB. TaskService now uses Backend.
  // These might be used for offline cache later.
  Future<String> addTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id!;
  }

  Future<List<Task>> getUserTasks(String userId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    task.updatedAt = DateTime.now();
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async { // Changed to String
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Routine settings operations
  Future<void> saveRoutineSettings(RoutineSettings settings) async {
    final db = await database;
    
    // Check if exists
    final existing = await getRoutineSettings(settings.userId);
    if (existing != null) {
      settings.id = existing.id;
      await db.update(
        'routine_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id],
      );
    } else {
      await db.insert('routine_settings', settings.toMap());
    }
  }

  Future<RoutineSettings?> getRoutineSettings(String userId) async {
    final db = await database;
    final maps = await db.query(
      'routine_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return RoutineSettings.fromMap(maps.first);
  }

  // Timer records operations
  Future<int> addTimerRecord(TimerRecord record) async {
    final db = await database;
    return await db.insert('timer_records', record.toMap());
  }

  Future<List<TimerRecord>> getTodayTimerRecords(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final db = await database;
    final maps = await db.query(
      'timer_records',
      where: 'user_id = ? AND start_time >= ? AND start_time < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );
    return maps.map((map) => TimerRecord.fromMap(map)).toList();
  }

  Future<int> getTaskTotalDuration(String taskId) async { // Changed to String
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM timer_records WHERE task_id = ?',
      [taskId],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  // Daily snapshot operations
  Future<void> saveDailySnapshot(DailySnapshot snapshot) async {
    final db = await database;
    
    // Check if exists
    final existing = await db.query(
      'daily_snapshots',
      where: 'user_id = ? AND date = ?',
      whereArgs: [snapshot.userId, snapshot.date.toIso8601String()],
    );

    if (existing.isNotEmpty) {
      final data = snapshot.toMap();
      data.remove('id'); // Never update ID to null
      
      await db.update(
        'daily_snapshots',
        data,
        where: 'user_id = ? AND date = ?',
        whereArgs: [snapshot.userId, snapshot.date.toIso8601String()],
      );
    } else {
      await db.insert('daily_snapshots', snapshot.toMap());
    }
  }

  Future<DailySnapshot?> getDailySnapshot(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    
    final db = await database;
    final maps = await db.query(
      'daily_snapshots',
      where: 'user_id = ? AND date = ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
      ],
      orderBy: 'id DESC', // Get latest if duplicates exist
    );
    if (maps.isEmpty) return null;
    return DailySnapshot.fromMap(maps.first);
  }

  // Get all timer records for analytics
  Future<List<TimerRecord>> getAllTimerRecords(String userId) async {
    final db = await database;
    final maps = await db.query(
      'timer_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => TimerRecord.fromMap(map)).toList();
  }

  // Get all daily snapshots for analytics
  Future<List<DailySnapshot>> getAllDailySnapshots(String userId) async {
    final db = await database;
    final maps = await db.query(
      'daily_snapshots',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => DailySnapshot.fromMap(map)).toList();
  }

  // Clear all data for a user (for testing/logout)
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('routine_settings', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}