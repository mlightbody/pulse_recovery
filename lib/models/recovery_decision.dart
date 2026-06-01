enum RecoveryDecisionState {
  progress,
  maintain,
  caution,
  recover,
}

enum RecoveryReasonTag {
  easySessionHandledWell,
  strongRecovery,
  normalResponse,
  hiddenLoad,
  fatigueMismatch,
  highStrain,
  weakRecovery,
}

class RecoveryDecision {
  final RecoveryDecisionState state;
  final RecoveryReasonTag reasonTag;

  const RecoveryDecision({
    required this.state,
    required this.reasonTag,
  });
}

class RecoveryDecisionResult {
  final RecoveryDecisionState state;
  final RecoveryReasonTag reasonTag;
  final String title;
  final String summary;
  final String recommendation;

  final double hrrScore;
  final double rpeScore;
  final double feelingScore;
  final double expectedRecovery;
  final double recoveryGap;
  final double fatigueSignal;

  RecoveryDecisionResult({
    required this.state,
    required this.reasonTag,
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.hrrScore,
    required this.rpeScore,
    required this.feelingScore,
    required this.expectedRecovery,
    required this.recoveryGap,
    required this.fatigueSignal,
  });
}