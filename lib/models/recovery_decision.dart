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

  // Backwards-compatible fields.
  final String title;
  final String summary;
  final String recommendation;

  // Structured result fields for the assessment result screen.
  final String recoveryTypeTitle;
  final String recoveryPatternDetail;
  final String testInterpretation;
  final String trainingFocus;
  final String specificSession;
  final String measurableTarget;
  final String responseWindow;
  final String progressRule;
  final String holdBackRule;

  // Numeric/debug fields.
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
    required this.recoveryTypeTitle,
    required this.recoveryPatternDetail,
    required this.testInterpretation,
    required this.trainingFocus,
    required this.specificSession,
    required this.measurableTarget,
    required this.responseWindow,
    required this.progressRule,
    required this.holdBackRule,
    required this.hrrScore,
    required this.rpeScore,
    required this.feelingScore,
    required this.expectedRecovery,
    required this.recoveryGap,
    required this.fatigueSignal,
  });
}