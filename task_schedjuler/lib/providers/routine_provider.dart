// lib/providers/routine_provider.dart
import 'package:flutter/foundation.dart';
import '../core/models/routine_settings.dart';
import '../services/database_service.dart';

class RoutineProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  RoutineSettings? _routineSettings;
  bool _isLoading = false;
  
  RoutineSettings? get routineSettings => _routineSettings;
  bool get isLoading => _isLoading;
  
  Future<void> loadSettings(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    _routineSettings = await _dbService.getRoutineSettings(userId);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> saveSettings({
    required String userId,
    required DateTime wakeTime,
    required DateTime sleepTime,
    required int dailyWorkTargetMinutes,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    final settings = RoutineSettings(
      userId: userId,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      dailyWorkTargetMinutes: dailyWorkTargetMinutes,
      updatedAt: DateTime.now(),
    );
    
    await _dbService.saveRoutineSettings(settings);
    _routineSettings = settings;
    
    _isLoading = false;
    notifyListeners();
  }
}
