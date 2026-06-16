class DataQualityResult {
  final String workoutQuality;
  final String recoveryQuality;
  final int workoutSampleCount;
  final int recoverySampleCount;
  final int largestWorkoutGapSeconds;
  final int largestRecoveryGapSeconds;
  final int distinctRecoveryHrValues;
  final bool hrrReliable;
  final bool peakReliable;
  final bool suspiciousFlatRecovery;
  final String confidenceLabel;
  final String message;

  const DataQualityResult({
    required this.workoutQuality,
    required this.recoveryQuality,
    required this.workoutSampleCount,
    required this.recoverySampleCount,
    required this.largestWorkoutGapSeconds,
    required this.largestRecoveryGapSeconds,
    required this.distinctRecoveryHrValues,
    required this.hrrReliable,
    required this.peakReliable,
    required this.suspiciousFlatRecovery,
    required this.confidenceLabel,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutQuality': workoutQuality,
      'recoveryQuality': recoveryQuality,
      'workoutSampleCount': workoutSampleCount,
      'recoverySampleCount': recoverySampleCount,
      'largestWorkoutGapSeconds': largestWorkoutGapSeconds,
      'largestRecoveryGapSeconds': largestRecoveryGapSeconds,
      'distinctRecoveryHrValues': distinctRecoveryHrValues,
      'hrrReliable': hrrReliable,
      'peakReliable': peakReliable,
      'suspiciousFlatRecovery': suspiciousFlatRecovery,
      'confidenceLabel': confidenceLabel,
      'message': message,
    };
  }
}

class BaselineComparisonResult {
  final int previousSessionCount;
  final bool hasEnoughHistory;
  final double? recentAverageRecoveryPercent120;
  final double? currentVsBaselineChange;
  final String trendLabel;
  final String message;

  const BaselineComparisonResult({
    required this.previousSessionCount,
    required this.hasEnoughHistory,
    required this.recentAverageRecoveryPercent120,
    required this.currentVsBaselineChange,
    required this.trendLabel,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'previousSessionCount': previousSessionCount,
      'hasEnoughHistory': hasEnoughHistory,
      'recentAverageRecoveryPercent120': recentAverageRecoveryPercent120,
      'currentVsBaselineChange': currentVsBaselineChange,
      'trendLabel': trendLabel,
      'message': message,
    };
  }
}

class DailyInsightResult {
  final String mainHeadline;
  final String dailySignal;
  final String patternContext;
  final String baselineMessage;
  final String coachingFocus;
  final String dataConfidenceLabel;
  final String dataQualityMessage;
  final List<String> badges;

  const DailyInsightResult({
    required this.mainHeadline,
    required this.dailySignal,
    required this.patternContext,
    required this.baselineMessage,
    required this.coachingFocus,
    required this.dataConfidenceLabel,
    required this.dataQualityMessage,
    required this.badges,
  });

  Map<String, dynamic> toMap() {
    return {
      'mainHeadline': mainHeadline,
      'dailySignal': dailySignal,
      'patternContext': patternContext,
      'baselineMessage': baselineMessage,
      'coachingFocus': coachingFocus,
      'dataConfidenceLabel': dataConfidenceLabel,
      'dataQualityMessage': dataQualityMessage,
      'badges': badges,
    };
  }
}