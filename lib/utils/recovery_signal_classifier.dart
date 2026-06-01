import '../models/recovery_metrics.dart';
import '../models/recovery_signals.dart';

class RecoverySignalClassifier {
  static RecoveryQuality recoveryQuality(RecoveryMetrics metrics) {
    if (metrics.hrrScore < 0.35) return RecoveryQuality.poor;
    if (metrics.hrrScore < 0.55) return RecoveryQuality.moderate;
    if (metrics.hrrScore < 0.75) return RecoveryQuality.good;
    return RecoveryQuality.strong;
  }

  static WorkoutDemand workoutDemand(int rpe) {
    if (rpe <= 4) return WorkoutDemand.easy;
    if (rpe <= 6) return WorkoutDemand.moderate;
    if (rpe <= 8) return WorkoutDemand.hard;
    return WorkoutDemand.veryHard;
  }

  static SubjectiveResponse subjectiveResponse(int feelingAfter) {
    if (feelingAfter <= 4) return SubjectiveResponse.poor;
    if (feelingAfter <= 6) return SubjectiveResponse.okay;
    if (feelingAfter <= 8) return SubjectiveResponse.good;
    return SubjectiveResponse.excellent;
  }

  static RecoveryShape recoveryShape(RecoveryMetrics metrics) {
    if (metrics.hrr60 <= 0 || metrics.secondMinuteDrop < 0) {
      return RecoveryShape.unclear;
    }

    if (metrics.hrr60 < 8 && metrics.secondMinuteDrop < 5) {
      return RecoveryShape.weak;
    }

    final ratio = metrics.secondMinuteRatio;
    if (ratio == null) return RecoveryShape.unclear;

    if (ratio < 0.5) {
      return RecoveryShape.fastStartThenStall;
    }

    if (ratio <= 1.2) {
      return RecoveryShape.sustained;
    }

    return RecoveryShape.delayed;
  }
}