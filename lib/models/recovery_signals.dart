enum RecoveryQuality {
  poor,
  moderate,
  good,
  strong,
}

enum WorkoutDemand {
  easy,
  moderate,
  hard,
  veryHard,
}

enum SubjectiveResponse {
  poor,
  okay,
  good,
  excellent,
}

enum RecoveryShape {
  weak,
  fastStartThenStall,
  sustained,
  delayed,
  unclear,
}

class RecoverySignals {
  final RecoveryQuality recoveryQuality;
  final WorkoutDemand workoutDemand;
  final SubjectiveResponse subjectiveResponse;
  final RecoveryShape recoveryShape;

  final bool easySessionHandledWell;
  final bool strongRecoveryHandledWell;
  final bool hiddenLoadSignal;
  final bool fatigueMismatch;
  final bool highStrainSignal;
  final bool weakRecoverySignal;

  const RecoverySignals({
    required this.recoveryQuality,
    required this.workoutDemand,
    required this.subjectiveResponse,
    required this.recoveryShape,
    required this.easySessionHandledWell,
    required this.strongRecoveryHandledWell,
    required this.hiddenLoadSignal,
    required this.fatigueMismatch,
    required this.highStrainSignal,
    required this.weakRecoverySignal,
  });
}