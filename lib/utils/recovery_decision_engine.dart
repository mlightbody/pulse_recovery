// lib/utils/recovery_decision_engine.dart

enum RecoveryDecisionState {
  progress,
  maintain,
  caution,
  recover,
}

class RecoveryDecisionResult {
  final RecoveryDecisionState state;
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

double _clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

/// Converts heart-rate recovery into a 0–1 score.
/// Reuses your existing peak HR, 60 sec HR, and 120 sec HR inputs.
double calculateHrrScore({
  required int peakHr,
  required int hr60,
  required int hr120,
}) {
  final drop60 = peakHr - hr60;
  final drop120 = peakHr - hr120;

  // Simple starting thresholds.
  // You can tune these later.
  final score60 = _clamp01(drop60 / 40.0);
  final score120 = _clamp01(drop120 / 60.0);

  // Weight early recovery slightly more heavily.
  return _clamp01((score60 * 0.6) + (score120 * 0.4));
}

RecoveryDecisionResult assessRecoveryDecision({
  required int peakHr,
  required int hr60,
  required int hr120,
  required int rpe, // 1–10
  required int feelingAfter, // 1–10
}) {
  final hrrScore = calculateHrrScore(
    peakHr: peakHr,
    hr60: hr60,
    hr120: hr120,
  );

  final rpeScore = _clamp01(rpe / 10.0);
  final feelingScore = _clamp01(feelingAfter / 10.0);

  final expectedRecovery = _clamp01(1.0 - rpeScore);
  final recoveryGap = hrrScore - expectedRecovery;
  final fatigueSignal = 1.0 - feelingScore;

  RecoveryDecisionState state;

  if (recoveryGap <= -0.30 && feelingScore <= 0.40) {
    state = RecoveryDecisionState.recover;
  } else if (recoveryGap <= -0.15 || feelingScore <= 0.50) {
    state = RecoveryDecisionState.caution;
  } else if (recoveryGap >= 0.20 && feelingScore >= 0.70) {
    state = RecoveryDecisionState.progress;
  } else {
    state = RecoveryDecisionState.maintain;
  }

  switch (state) {
    case RecoveryDecisionState.progress:
      return RecoveryDecisionResult(
        state: state,
        title: 'Ready to progress',
        summary:
            'Your recovery was better than expected for the effort level you reported.',
        recommendation:
            'You appear to be coping well with this training load. Consider increasing intensity slightly next time, but keep the increase modest.',
        hrrScore: hrrScore,
        rpeScore: rpeScore,
        feelingScore: feelingScore,
        expectedRecovery: expectedRecovery,
        recoveryGap: recoveryGap,
        fatigueSignal: fatigueSignal,
      );

    case RecoveryDecisionState.maintain:
      return RecoveryDecisionResult(
        state: state,
        title: 'Maintain current level',
        summary:
            'Your recovery response is broadly in line with how hard the session felt.',
        recommendation:
            'This looks like an appropriate training load. Keep the next session similar and look for steady improvement over time.',
        hrrScore: hrrScore,
        rpeScore: rpeScore,
        feelingScore: feelingScore,
        expectedRecovery: expectedRecovery,
        recoveryGap: recoveryGap,
        fatigueSignal: fatigueSignal,
      );

    case RecoveryDecisionState.caution:
      return RecoveryDecisionResult(
        state: state,
        title: 'Use caution',
        summary:
            'Your recovery was a little slower than expected, or you reported feeling below normal after the session.',
        recommendation:
            'Consider reducing intensity next time, extending your warm-down, or allowing more recovery before another hard session.',
        hrrScore: hrrScore,
        rpeScore: rpeScore,
        feelingScore: feelingScore,
        expectedRecovery: expectedRecovery,
        recoveryGap: recoveryGap,
        fatigueSignal: fatigueSignal,
      );

    case RecoveryDecisionState.recover:
      return RecoveryDecisionResult(
        state: state,
        title: 'Prioritise recovery',
        summary:
            'Your heart-rate recovery and how you felt after the workout both suggest your body was under strain.',
        recommendation:
            'Avoid another hard session immediately. Choose rest, walking, mobility work, or a very easy recovery session.',
        hrrScore: hrrScore,
        rpeScore: rpeScore,
        feelingScore: feelingScore,
        expectedRecovery: expectedRecovery,
        recoveryGap: recoveryGap,
        fatigueSignal: fatigueSignal,
      );
  }
}