import '../models/heart_rate_sample.dart';
import '../models/recovery_session_insight.dart';

class RecoveryDataQualityAnalyser {
  static DataQualityResult analyse({
    required int peakHr,
    required int hr60,
    required int hr120,
    List<HeartRateSample> samples = const [],
    DateTime? workoutStartedAt,
    DateTime? recoveryStartedAt,
  }) {
    if (samples.isEmpty || recoveryStartedAt == null) {
      return const DataQualityResult(
        workoutQuality: 'manual',
        recoveryQuality: 'manual',
        workoutSampleCount: 0,
        recoverySampleCount: 0,
        largestWorkoutGapSeconds: 0,
        largestRecoveryGapSeconds: 0,
        distinctRecoveryHrValues: 0,
        hrrReliable: true,
        peakReliable: true,
        suspiciousFlatRecovery: false,
        confidenceLabel: 'Manual entry',
        message:
            'This assessment used entered recovery values rather than a full heart-rate curve.',
      );
    }

    final sorted = [...samples]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recoveryEnd = recoveryStartedAt.add(const Duration(seconds: 130));

    final workoutSamples = sorted.where((sample) {
      return sample.timestamp.isBefore(recoveryStartedAt);
    }).toList();

    final recoverySamples = sorted.where((sample) {
      return !sample.timestamp.isBefore(recoveryStartedAt) &&
          !sample.timestamp.isAfter(recoveryEnd);
    }).toList();

    final largestWorkoutGap = _largestGapSeconds(workoutSamples);
    final largestRecoveryGap = _largestGapSeconds(recoverySamples);
    final distinctRecoveryValues = recoverySamples.map((s) => s.bpm).toSet().length;

    final suspiciousFlatRecovery =
        recoverySamples.length >= 40 && distinctRecoveryValues <= 2;

    final workoutQuality = _qualityFromSamplesAndGap(
      sampleCount: workoutSamples.length,
      largestGapSeconds: largestWorkoutGap,
      goodSampleCount: 60,
      moderateSampleCount: 30,
    );

    String recoveryQuality = _qualityFromSamplesAndGap(
      sampleCount: recoverySamples.length,
      largestGapSeconds: largestRecoveryGap,
      goodSampleCount: 80,
      moderateSampleCount: 50,
    );

    if (suspiciousFlatRecovery) {
      recoveryQuality = 'suspicious';
    }

    final hrrReliable = recoveryQuality == 'good' || recoveryQuality == 'moderate';
    final peakReliable = workoutQuality == 'good' || workoutQuality == 'moderate';

    final confidenceLabel = _confidenceLabel(
      recoveryQuality: recoveryQuality,
      suspiciousFlatRecovery: suspiciousFlatRecovery,
    );

    final message = _message(
      workoutQuality: workoutQuality,
      recoveryQuality: recoveryQuality,
      suspiciousFlatRecovery: suspiciousFlatRecovery,
      largestWorkoutGap: largestWorkoutGap,
      largestRecoveryGap: largestRecoveryGap,
    );

    return DataQualityResult(
      workoutQuality: workoutQuality,
      recoveryQuality: recoveryQuality,
      workoutSampleCount: workoutSamples.length,
      recoverySampleCount: recoverySamples.length,
      largestWorkoutGapSeconds: largestWorkoutGap,
      largestRecoveryGapSeconds: largestRecoveryGap,
      distinctRecoveryHrValues: distinctRecoveryValues,
      hrrReliable: hrrReliable,
      peakReliable: peakReliable,
      suspiciousFlatRecovery: suspiciousFlatRecovery,
      confidenceLabel: confidenceLabel,
      message: message,
    );
  }

  static int _largestGapSeconds(List<HeartRateSample> samples) {
    if (samples.length < 2) return 0;

    final sorted = [...samples]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var largest = 0;

    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].timestamp.difference(sorted[i - 1].timestamp).inSeconds.abs();

      if (gap > largest) {
        largest = gap;
      }
    }

    return largest;
  }

  static String _qualityFromSamplesAndGap({
    required int sampleCount,
    required int largestGapSeconds,
    required int goodSampleCount,
    required int moderateSampleCount,
  }) {
    if (sampleCount >= goodSampleCount && largestGapSeconds <= 10) {
      return 'good';
    }

    if (sampleCount >= moderateSampleCount && largestGapSeconds <= 20) {
      return 'moderate';
    }

    return 'poor';
  }

  static String _confidenceLabel({
    required String recoveryQuality,
    required bool suspiciousFlatRecovery,
  }) {
    if (suspiciousFlatRecovery) {
      return 'Low recovery confidence';
    }

    switch (recoveryQuality) {
      case 'good':
        return 'High recovery confidence';
      case 'moderate':
        return 'Moderate recovery confidence';
      case 'manual':
        return 'Manual entry';
      default:
        return 'Low recovery confidence';
    }
  }

  static String _message({
    required String workoutQuality,
    required String recoveryQuality,
    required bool suspiciousFlatRecovery,
    required int largestWorkoutGap,
    required int largestRecoveryGap,
  }) {
    if (suspiciousFlatRecovery) {
      return 'The recovery data contained many samples but very little heart-rate variation. This may indicate stale or repeated sensor values.';
    }

    if (recoveryQuality == 'good' && workoutQuality == 'good') {
      return 'Good heart-rate coverage during workout and recovery.';
    }

    if (recoveryQuality == 'good' && workoutQuality != 'good') {
      return 'Recovery data looks usable, but the workout signal had gaps. Peak HR may be less reliable.';
    }

    if (recoveryQuality == 'moderate') {
      return 'Recovery data is usable, but there were some gaps. Treat small changes cautiously.';
    }

    return 'Recovery data was incomplete. The recovery score may be unreliable.';
  }
}