// lib/providers/analytics_provider.dart
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../services/ai_service.dart';
import '../core/constants/api_keys.dart';
import '../core/models/analytics_data.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final AIService _aiService = AIService();
  
  AnalyticsProvider() {
    _aiService.setApiKey(ApiKeys.groqApiKey);
  }
  
  bool _isLoading = false;
  Map<String, double> _dailyCompletionData = {};
  Map<String, int> _sessionDistribution = {};
  List<String> _aiInsights = [];
  String? _habitPattern;
  String? _suggestion;
  AnalyticsData? _lastAnalyticsData;
  String? _error; // Store error message
  
  bool get isLoading => _isLoading;
  Map<String, double> get dailyCompletionData => _dailyCompletionData;
  Map<String, int> get sessionDistribution => _sessionDistribution;
  List<String> get aiInsights => _aiInsights;
  String? get habitPattern => _habitPattern;
  String? get suggestion => _suggestion;
  AnalyticsData? get lastAnalyticsData => _lastAnalyticsData;
  String? get error => _error;
  
  Future<void> loadInsights(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Optional: Trigger backend to generate snapshot so we have latest team data
      // We can do this in the background or wait. Let's do it first.
      await _analyticsService.generateSnapshot(userId);

      // 2. Get analytics data (this will now try cloud first)
      final analytics = await _analyticsService.calculateAnalytics(userId);
      _lastAnalyticsData = analytics;
      _dailyCompletionData = await _analyticsService.getWeeklyCompletion(userId);
      _sessionDistribution = await _analyticsService.getSessionDistribution(userId);
      
      // 3. Get AI insights (Groq)
      // Note: Groq still uses the analytics object we just got, 
      // which now includes cloud-synced collaborator data!
      final aiResponse = await _aiService.getInsights(analytics);
      _aiInsights = List<String>.from(aiResponse['performanceInsights'] ?? []);
      _habitPattern = aiResponse['habitPattern'];
      _suggestion = aiResponse['gentleSuggestion'];
      _error = null; // Clear error on success
    } catch (e) {
      // Fallback data
      _error = e.toString(); // Capture error
      
      // Attempt local-only fallback if it didn't already happen inside calculateAnalytics
      _aiInsights = [
        'Your consistency is improving',
        'Try to reduce interruptions during focus sessions'
      ];
      _habitPattern = 'You work best in the morning hours';
      _suggestion = 'Consider scheduling important tasks during your most productive hours';
    }
    
    _isLoading = false;
    notifyListeners();
  }
}