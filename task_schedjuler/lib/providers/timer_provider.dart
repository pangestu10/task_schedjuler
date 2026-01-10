// lib/providers/timer_provider.dart
import 'package:flutter/foundation.dart';
import '../services/timer_service.dart';
import '../services/task_service.dart';
import '../services/database_service.dart';
import '../core/enums/timer_status.dart';

class TimerProvider with ChangeNotifier {
  final TimerService _timerService = TimerService();
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();
  
  TimerStatus _status = TimerStatus.idle;
  int _elapsedSeconds = 0;
  int? _currentTaskId;
  String? _currentUserId;
  
  TimerStatus get status => _status;
  int get elapsedSeconds => _elapsedSeconds;
  int? get currentTaskId => _currentTaskId;
  
  TimerProvider() {
    _timerService.elapsedSecondsStream.listen((seconds) {
      _elapsedSeconds = seconds;
      notifyListeners();
    });
  }
  
  Future<void> selectTask(int taskId) async {
    _elapsedSeconds = await _dbService.getTaskTotalDuration(taskId);
    notifyListeners();
  }

  Future<void> startTimer({required String userId, int? taskId}) async {
    int initialDuration = 0;
    if (taskId != null) {
      initialDuration = await _dbService.getTaskTotalDuration(taskId);
    }
    
    _timerService.startTimer(
      userId: userId, 
      taskId: taskId,
      initialDuration: initialDuration
    );
    _status = TimerStatus.running;
    _currentTaskId = taskId;
    _currentUserId = userId;
    notifyListeners();
  }
  
  Future<void> stopTimer({required String stopReason}) async {
    await _timerService.stopTimer(stopReason: stopReason);
    
    if (_currentUserId != null) {
      await _taskService.generateDailySnapshot(_currentUserId!);
    }

    _status = TimerStatus.idle;
    _currentTaskId = null;
    notifyListeners();
  }
  
  void pauseTimer() {
    _timerService.pauseTimer();
    _status = TimerStatus.paused;
    notifyListeners();
  }
  
  void resumeTimer() {
    _timerService.resumeTimer();
    _status = TimerStatus.running;
    notifyListeners();
  }
  
  String getFormattedTime() {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
}
