// lib/services/ai_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/models/analytics_data.dart';
import '../core/constants/api_keys.dart';

class AIService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  late String _apiKey;
  
  AIService() {
    _initializeApiKey();
  }
  
  void _initializeApiKey() {
    final apiKey = ApiKeys.groqApiKey;
    if (apiKey == 'YOUR_GROQ_API_KEY_HERE' || apiKey.isEmpty) {
      _apiKey = '';
    } else {
      _apiKey = apiKey;
    }
  }
  
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }
  
  bool get hasValidApiKey => _apiKey.isNotEmpty && _apiKey != 'YOUR_GROQ_API_KEY_HERE';
  
  Future<Map<String, dynamic>> getInsights(AnalyticsData analytics) async {
    if (!hasValidApiKey) {
      return _getDefaultInsights();
    }
    
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "llama-3.1-8b-instant",
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful productivity assistant. Provide insights based on analytics data in Indonesian language.
              Always respond with exactly 3 items in this JSON format:
              {
                "performanceInsights": ["insight1 (Bahasa Indonesia)", "insight2 (Bahasa Indonesia)"],
                "habitPattern": "pattern description (Bahasa Indonesia)",
                "gentleSuggestion": "suggestion text (Bahasa Indonesia)"
              }
              Rules:
              1. NEVER schedule tasks for user
              2. NEVER give commands
              3. Only provide observations and gentle suggestions
              4. Keep insights positive and constructive
              5. Use the provided data only
              6. OUTPUT MUST BE IN INDONESIAN'''
            },
            {
              'role': 'user',
              'content': '''Analytics Data:
              - Daily Completion Rate: ${analytics.dailyCompletionRate.toStringAsFixed(1)}%
              - Planned vs Actual Difference: ${analytics.plannedVsActualDifference} minutes
              - Average Focus Duration: ${analytics.averageFocusDuration.toStringAsFixed(0)} seconds
              - Interruption Frequency: ${analytics.interruptionFrequency} times

              - Dominant Working Hours: ${analytics.dominantWorkingHours}
              - Productivity Score: ${analytics.productivityScore.toStringAsFixed(1)} / 100
              - Performance Level: ${analytics.performanceLevel}
              
              Provide insights based on this data.'''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );
      
      final content = response.data['choices'][0]['message']['content'];
      return _parseAIResponse(content);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('AI Error: $errorMsg');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }

  Future<List<String>> generateTaskSteps(String taskTitle) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "llama-3.1-8b-instant",
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful task planner. Break down the user's task into 3-5 actionable sub-tasks (steps). 
              Output MUST be a valid JSON Array of strings in Indonesian Language.
              Example: ["Step 1", "Step 2", "Step 3"]
              Rules:
              1. Keep steps concise and actionable
              2. Output ONLY the JSON array
              3. No extra text or markdown
              4. Language: Indonesian'''
            },
            {
              'role': 'user',
              'content': 'Task: $taskTitle'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        },
      );
      
      final content = response.data['choices'][0]['message']['content'];
      return _parseStepsResponse(content);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('AI Error: $errorMsg');
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }

  List<String> _parseStepsResponse(String content) {
    try {
      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = content.substring(jsonStart, jsonEnd + 1);
        final List<dynamic> list = jsonDecode(jsonStr);
        return list.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Fall through
    }
    return [];
  }
  
  Map<String, dynamic> _parseAIResponse(String content) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = content.substring(jsonStart, jsonEnd + 1);
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
      // Fall through to default
    }
    return _getDefaultInsights();
  }
  
  Map<String, dynamic> _getDefaultInsights() {
    return {
      'performanceInsights': [
        'You\'re maintaining consistency in your workflow.',
        'Your planning shows good structure.'
      ],
      'habitPattern': 'You tend to work during your scheduled hours.',
      'gentleSuggestion': 'Consider taking short breaks between focus sessions.'
    };
  }
}