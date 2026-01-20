// lib/services/timer_service.dart
import 'dart:async';
import '../core/models/timer_record.dart';
import './database_service.dart';

class TimerService {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedSeconds = 0;
  int _accumulatedSeconds = 0; // State to track continued sessions
  TimerRecord? _currentRecord;
  final DatabaseService _dbService = DatabaseService();
  
  Stream<int> get elapsedSecondsStream => 
      Stream.periodic(const Duration(seconds: 1), (_) => _elapsedSeconds);
  
  // Changed taskId to String
  void startTimer({required String userId, String? taskId, int initialDuration = 0}) {
    if (_timer != null) return;
    
    _accumulatedSeconds = initialDuration;
    
    _currentRecord = TimerRecord(
      userId: userId,
      taskId: taskId,
      startTime: DateTime.now(),
      durationSeconds: 0,
      stopReason: 'running',
    );
    
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds = _accumulatedSeconds + _stopwatch.elapsed.inSeconds;
    });
  }
  
  Future<void> stopTimer({required String stopReason}) async {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    
    if (_currentRecord != null) {
      _currentRecord!.endTime = DateTime.now();
      _currentRecord!.durationSeconds = _stopwatch.elapsed.inSeconds; // Only record this segment's duration
      _currentRecord!.stopReason = stopReason;
      
      await _dbService.addTimerRecord(_currentRecord!);
    }
    
    _stopwatch.reset();
    _elapsedSeconds = 0;
    _accumulatedSeconds = 0;

    _currentRecord = null;
  }
  
  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }
  
  void resumeTimer() {
    if (_timer != null) return;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds = _accumulatedSeconds + _stopwatch.elapsed.inSeconds;
    });
  }
  
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
  }
}