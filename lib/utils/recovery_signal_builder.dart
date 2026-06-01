import '../models/recovery_input.dart';
import '../models/recovery_metrics.dart';
import '../models/recovery_signals.dart';
import 'recovery_signal_classifier.dart';

class RecoverySignalBuilder {
  static RecoverySignals build({
    required RecoveryInput input,
    required RecoveryMetrics metrics,
  }) {
    final recoveryQuality =
        RecoverySignalClassifier.recoveryQuality(metrics);

    final workoutDemand =
        RecoverySignalClassifier.workoutDemand(input.rpe);

    final subjectiveResponse =
        RecoverySignalClassifier.subjectiveResponse(input.feelingAfter);

    final recoveryShape =
        RecoverySignalClassifier.recoveryShape(metrics);

    final feelsGood =
        subjectiveResponse == SubjectiveResponse.good ||
        subjectiveResponse == SubjectiveResponse.excellent;

    final feelsPoor =
        subjectiveResponse == SubjectiveResponse.poor;

    final notPoorRecovery = recoveryQuality != RecoveryQuality.poor;

    final goodOrStrongRecovery =
        recoveryQuality == RecoveryQuality.good ||
        recoveryQuality == RecoveryQuality.strong;

    final easySessionHandledWell =
        workoutDemand == WorkoutDemand.easy &&
        feelsGood &&
        notPoorRecovery;

    final strongRecoveryHandledWell =
        recoveryQuality == RecoveryQuality.strong &&
        feelsGood;

    final hiddenLoadSignal =
        recoveryQuality == RecoveryQuality.poor &&
        feelsGood;

    final fatigueMismatch =
        goodOrStrongRecovery &&
        feelsPoor &&
        (workoutDemand == WorkoutDemand.hard ||
            workoutDemand == WorkoutDemand.veryHard);

    final highStrainSignal =
        recoveryQuality == RecoveryQuality.poor &&
        feelsPoor;

    final weakRecoverySignal =
        recoveryQuality == RecoveryQuality.poor ||
        recoveryShape == RecoveryShape.weak;

    return RecoverySignals(
      recoveryQuality: recoveryQuality,
      workoutDemand: workoutDemand,
      subjectiveResponse: subjectiveResponse,
      recoveryShape: recoveryShape,
      easySessionHandledWell: easySessionHandledWell,
      strongRecoveryHandledWell: strongRecoveryHandledWell,
      hiddenLoadSignal: hiddenLoadSignal,
      fatigueMismatch: fatigueMismatch,
      highStrainSignal: highStrainSignal,
      weakRecoverySignal: weakRecoverySignal,
    );
  }
}