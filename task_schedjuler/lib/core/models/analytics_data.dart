// lib/core/models/analytics_data.dart

class AnalyticsData {
  final double dailyCompletionRate;
  final int plannedVsActualDifference;
  final double averageFocusDuration;
  final int interruptionFrequency;
  final String dominantWorkingHours;

  AnalyticsData({
    required this.dailyCompletionRate,
    required this.plannedVsActualDifference,
    required this.averageFocusDuration,
    required this.interruptionFrequency,
    required this.dominantWorkingHours,
  });

  // Create a copy with updated values
  AnalyticsData copyWith({
    double? dailyCompletionRate,
    int? plannedVsActualDifference,
    double? averageFocusDuration,
    int? interruptionFrequency,
    String? dominantWorkingHours,
  }) {
    return AnalyticsData(
      dailyCompletionRate: dailyCompletionRate ?? this.dailyCompletionRate,
      plannedVsActualDifference: plannedVsActualDifference ?? this.plannedVsActualDifference,
      averageFocusDuration: averageFocusDuration ?? this.averageFocusDuration,
      interruptionFrequency: interruptionFrequency ?? this.interruptionFrequency,
      dominantWorkingHours: dominantWorkingHours ?? this.dominantWorkingHours,
    );
  }

  // Get completion rate as formatted string
  String get formattedCompletionRate => '${dailyCompletionRate.toStringAsFixed(1)}%';

  // Get planned vs actual difference as formatted string
  String get formattedPlannedVsActual {
    final diff = plannedVsActualDifference.abs();
    final sign = plannedVsActualDifference >= 0 ? '-' : '+';
    return '$sign${diff}min';
  }

  // Get average focus duration in minutes
  double get averageFocusDurationMinutes => averageFocusDuration / 60.0;

  // Get average focus duration in hours
  double get averageFocusDurationHours => averageFocusDuration / 3600.0;

  // Get formatted focus duration
  String get formattedFocusDuration {
    final hours = averageFocusDuration ~/ 3600;
    final minutes = (averageFocusDuration % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get formatted interruption frequency
  String get formattedInterruptionFrequency {
    if (interruptionFrequency == 0) return 'No interruptions';
    if (interruptionFrequency == 1) return '1 interruption';
    return '$interruptionFrequency interruptions';
  }

  // Get productivity score (0-100)
  double get productivityScore {
    double score = 0.0;
    
    // Daily completion rate (30% weight)
    score += (dailyCompletionRate / 100.0) * 30.0;
    
    // Time adherence (25% weight)
    final timeAdherence = plannedVsActualDifference.abs() <= 60 ? 1.0 : 
                        plannedVsActualDifference.abs() <= 120 ? 0.7 : 0.3;
    score += timeAdherence * 25.0;
    
    // Focus duration (25% weight)
    final focusScore = (averageFocusDurationMinutes / 25.0).clamp(0.0, 1.0);
    score += focusScore * 25.0;
    
    // Low interruptions (20% weight)
    final interruptionScore = interruptionFrequency == 0 ? 1.0 :
                           interruptionFrequency <= 2 ? 0.7 :
                           interruptionFrequency <= 5 ? 0.4 : 0.1;
    score += interruptionScore * 20.0;
    
    return score.clamp(0.0, 100.0);
  }

  // Get performance level
  String get performanceLevel {
    final score = productivityScore;
    if (score >= 90) return 'Exceptional';
    if (score >= 75) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  // Get performance emoji
  String get performanceEmoji {
    final score = productivityScore;
    if (score >= 90) return '🏆';
    if (score >= 75) return '🌟';
    if (score >= 60) return '👍';
    if (score >= 40) return '😐';
    return '📈';
  }

  // Check if user is consistent
  bool get isConsistent => dailyCompletionRate >= 70.0;

  // Check if user has good time management
  bool get hasGoodTimeManagement => plannedVsActualDifference.abs() <= 60;

  // Check if user has good focus
  bool get hasGoodFocus => averageFocusDurationMinutes >= 15.0;

  // Check if user has low interruptions
  bool get hasLowInterruptions => interruptionFrequency <= 2;

  // Get strengths list
  List<String> get strengths {
    final strengths = <String>[];
    
    if (isConsistent) strengths.add('Consistent task completion');
    if (hasGoodTimeManagement) strengths.add('Good time management');
    if (hasGoodFocus) strengths.add('Strong focus ability');
    if (hasLowInterruptions) strengths.add('Low interruption rate');
    
    return strengths;
  }

  // Get improvement areas list
  List<String> get improvementAreas {
    final areas = <String>[];
    
    if (!isConsistent) areas.add('Improve daily consistency');
    if (!hasGoodTimeManagement) areas.add('Better time estimation');
    if (!hasGoodFocus) areas.add('Enhance focus duration');
    if (!hasLowInterruptions) areas.add('Reduce interruptions');
    
    return areas;
  }

  // Get recommendations
  List<String> get recommendations {
    final recommendations = <String>[];
    
    if (dailyCompletionRate < 50) {
      recommendations.add('Consider breaking down large tasks into smaller ones');
    }
    
    if (plannedVsActualDifference < -60) {
      recommendations.add('Try setting more realistic time estimates');
    } else if (plannedVsActualDifference > 60) {
      recommendations.add('You might be underestimating your capacity');
    }
    
    if (averageFocusDurationMinutes < 15) {
      recommendations.add('Try the Pomodoro technique to improve focus');
    }
    
    if (interruptionFrequency > 5) {
      recommendations.add('Create a distraction-free work environment');
    }
    
    return recommendations;
  }

  // Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'dailyCompletionRate': dailyCompletionRate,
      'plannedVsActualDifference': plannedVsActualDifference,
      'averageFocusDuration': averageFocusDuration,
      'interruptionFrequency': interruptionFrequency,
      'dominantWorkingHours': dominantWorkingHours,
      'productivityScore': productivityScore,
      'performanceLevel': performanceLevel,
    };
  }

  // Create from map for JSON deserialization
  factory AnalyticsData.fromMap(Map<String, dynamic> map) {
    return AnalyticsData(
      dailyCompletionRate: (map['dailyCompletionRate'] as num?)?.toDouble() ?? 0.0,
      plannedVsActualDifference: map['plannedVsActualDifference'] as int? ?? 0,
      averageFocusDuration: (map['averageFocusDuration'] as num?)?.toDouble() ?? 0.0,
      interruptionFrequency: map['interruptionFrequency'] as int? ?? 0,
      dominantWorkingHours: map['dominantWorkingHours'] as String? ?? '09:00',
    );
  }

  @override
  String toString() {
    return 'AnalyticsData(completionRate: $formattedCompletionRate, focusDuration: $formattedFocusDuration, productivity: $performanceLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsData &&
        other.dailyCompletionRate == dailyCompletionRate &&
        other.plannedVsActualDifference == plannedVsActualDifference &&
        other.averageFocusDuration == averageFocusDuration &&
        other.interruptionFrequency == interruptionFrequency &&
        other.dominantWorkingHours == dominantWorkingHours;
  }

  @override
  int get hashCode {
    return Object.hash(
      dailyCompletionRate,
      plannedVsActualDifference,
      averageFocusDuration,
      interruptionFrequency,
      dominantWorkingHours,
    );
  }
}