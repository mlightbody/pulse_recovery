import '/services/trend_service.dart';

import '../models/recovery_decision.dart';
import '../models/recovery_input.dart';
import 'recovery_metrics_calculator.dart';
import 'recovery_signal_builder.dart';
import 'recovery_decision_policy.dart';
import 'recovery_message_builder.dart';

export '../models/recovery_decision.dart';
export '../models/recovery_input.dart';
export '../models/recovery_metrics.dart';
export '../models/recovery_signals.dart';
export 'recovery_input_validator.dart';
export 'recovery_metrics_calculator.dart';
export 'recovery_signal_classifier.dart';
export 'recovery_signal_builder.dart';
export 'recovery_decision_policy.dart';
export 'recovery_message_builder.dart';

enum RecoveryPatternDecision {
  buildingBaseline,
  improvingRecovery,
  stableRecovery,
  recoveryUnderStrain,
  slowStartStrongContinuation,
  fastStartThenStall,
  variableRecovery,
  hiddenLoad,
  fatigueMismatch,
}

class PersonalisedRecoveryAdvice {
  final RecoveryPatternDecision pattern;
  final String patternTitle;
  final String whatItMeans;
  final List<String> possibleReasons;
  final String coachingFocus;
  final String whatToTrackNext;
  final String confidence;

  const PersonalisedRecoveryAdvice({
    required this.pattern,
    required this.patternTitle,
    required this.whatItMeans,
    required this.possibleReasons,
    required this.coachingFocus,
    required this.whatToTrackNext,
    required this.confidence,
  });
}

double calculateHrrScore({
  required int peakHr,
  required int hr60,
  required int hr120,
}) {
  final input = RecoveryInput(
    peakHr: peakHr,
    hr60: hr60,
    hr120: hr120,
    rpe: 5,
    feelingAfter: 5,
  );

  return RecoveryMetricsCalculator.calculate(input).hrrScore;
}

RecoveryDecisionResult assessRecoveryDecision({
  required int peakHr,
  required int hr60,
  required int hr120,
  required int rpe,
  required int feelingAfter,
  String? activityType,
}) {
  final input = RecoveryInput(
    peakHr: peakHr,
    hr60: hr60,
    hr120: hr120,
    rpe: rpe,
    feelingAfter: feelingAfter,
    activityType: activityType,
  );

  final metrics = RecoveryMetricsCalculator.calculate(input);

  final signals = RecoverySignalBuilder.build(
    input: input,
    metrics: metrics,
  );

  final decision = RecoveryDecisionPolicy.decide(signals);

  final rpeScore = clamp01(rpe / 10.0);
  final feelingScore = clamp01(feelingAfter / 10.0);

  // Kept for display/debug compatibility with the previous engine.
  // The final decision is now made from interpretable signals rather than
  // relying only on recoveryGap.
  final expectedRecovery = clamp01(1.0 - rpeScore);
  final recoveryGap = metrics.hrrScore - expectedRecovery;
  final fatigueSignal = 1.0 - feelingScore;

  return RecoveryDecisionResult(
    state: decision.state,
    reasonTag: decision.reasonTag,
    title: RecoveryMessageBuilder.titleFor(decision),
    summary: RecoveryMessageBuilder.summaryFor(decision),
    recommendation: RecoveryMessageBuilder.recommendationFor(decision),
    hrrScore: metrics.hrrScore,
    rpeScore: rpeScore,
    feelingScore: feelingScore,
    expectedRecovery: expectedRecovery,
    recoveryGap: recoveryGap,
    fatigueSignal: fatigueSignal,
  );
}

PersonalisedRecoveryAdvice buildPersonalisedRecoveryAdvice({
  required RecoveryTrendSummary trend,
  String? activityType,
}) {
  final activity = (activityType ?? trend.latestActivityType ?? 'other')
      .toLowerCase()
      .trim();

  if (trend.assessmentCount < 3) {
    return const PersonalisedRecoveryAdvice(
      pattern: RecoveryPatternDecision.buildingBaseline,
      patternTitle: 'Building your baseline',
      whatItMeans:
          'There is not enough history yet to make a strong trend judgement. The app is learning what normal recovery looks like for you.',
      possibleReasons: [
        'Early tests can vary depending on workout type, effort, hydration, sleep and measurement timing.',
      ],
      coachingFocus:
          'Keep the next few assessments as consistent as possible: similar workout type, similar effort, and the same 60s and 120s timing.',
      whatToTrackNext:
          'Complete at least 3 assessments so your personal trend line becomes more meaningful.',
      confidence: 'Low confidence: based on limited history.',
    );
  }

  final pattern = _choosePattern(trend);
  final reasons = _choosePossibleReasons(trend, activity);
  final activityModifier = _activityModifier(activity, pattern);

  return PersonalisedRecoveryAdvice(
    pattern: pattern,
    patternTitle: _patternTitle(pattern),
    whatItMeans: _whatItMeans(pattern, trend),
    possibleReasons: reasons,
    coachingFocus: _coachingFocus(
      pattern,
      trend,
      activity,
      activityModifier,
    ),
    whatToTrackNext: _whatToTrackNext(pattern, trend, activity),
    confidence: _confidenceText(trend),
  );
}

RecoveryPatternDecision _choosePattern(RecoveryTrendSummary trend) {
  if (trend.possibleHiddenLoadMismatch) {
    return RecoveryPatternDecision.hiddenLoad;
  }

  if (trend.possibleFatigueMismatch) {
    return RecoveryPatternDecision.fatigueMismatch;
  }

  if (trend.trendDirection == TrendDirection.declining &&
      trend.stalledPatternCountLast5 >= 3) {
    return RecoveryPatternDecision.recoveryUnderStrain;
  }

  if (trend.recoveryGapTrend == RecoveryGapTrend.widening) {
    return RecoveryPatternDecision.slowStartStrongContinuation;
  }

  if (trend.recoveryGapTrend == RecoveryGapTrend.narrowing ||
      trend.stalledPatternCountLast5 >= 3) {
    return RecoveryPatternDecision.fastStartThenStall;
  }

  final variability = trend.recoveryVariability;
  if (variability != null && variability >= 10) {
    return RecoveryPatternDecision.variableRecovery;
  }

  if (trend.trendDirection == TrendDirection.improving) {
    return RecoveryPatternDecision.improvingRecovery;
  }

  if (trend.trendDirection == TrendDirection.declining) {
    return RecoveryPatternDecision.recoveryUnderStrain;
  }

  return RecoveryPatternDecision.stableRecovery;
}

String _patternTitle(RecoveryPatternDecision pattern) {
  switch (pattern) {
    case RecoveryPatternDecision.buildingBaseline:
      return 'Building your baseline';
    case RecoveryPatternDecision.improvingRecovery:
      return 'Improving recovery';
    case RecoveryPatternDecision.stableRecovery:
      return 'Stable recovery';
    case RecoveryPatternDecision.recoveryUnderStrain:
      return 'Recovery under strain';
    case RecoveryPatternDecision.slowStartStrongContinuation:
      return 'Slow start, strong continuation';
    case RecoveryPatternDecision.fastStartThenStall:
      return 'Fast start, then stall';
    case RecoveryPatternDecision.variableRecovery:
      return 'Variable recovery';
    case RecoveryPatternDecision.hiddenLoad:
      return 'Hidden load signal';
    case RecoveryPatternDecision.fatigueMismatch:
      return 'Recovery mismatch';
  }
}

String _whatItMeans(
  RecoveryPatternDecision pattern,
  RecoveryTrendSummary trend,
) {
  switch (pattern) {
    case RecoveryPatternDecision.buildingBaseline:
      return 'The app is still learning your normal recovery response. Avoid reading too much into a single result.';

    case RecoveryPatternDecision.improvingRecovery:
      return 'Your 120-second recovery is improving compared with your recent baseline. This usually suggests your body is coping better with the current training load.';

    case RecoveryPatternDecision.stableRecovery:
      return 'Your recovery is broadly consistent with recent assessments. This suggests your current training and recovery pattern is fairly steady.';

    case RecoveryPatternDecision.recoveryUnderStrain:
      return 'Your recent recovery is weaker than your usual baseline, or a slower pattern is repeating. This may suggest accumulated load or incomplete recovery.';

    case RecoveryPatternDecision.slowStartStrongContinuation:
      return 'Your first-minute recovery was relatively slower, but your heart rate continued to fall strongly into the second minute. That widening 60s-to-120s gap is worth tracking.';

    case RecoveryPatternDecision.fastStartThenStall:
      return 'Your heart rate dropped well early, but there was less additional recovery into the second minute. This can suggest a plateau after the initial recovery response.';

    case RecoveryPatternDecision.variableRecovery:
      return 'Your recovery results are moving around more than usual. That can make it harder to interpret progress from a single test.';

    case RecoveryPatternDecision.hiddenLoad:
      return 'You felt fairly okay, but your recovery numbers were slower than expected. This can sometimes show load before it is obvious subjectively.';

    case RecoveryPatternDecision.fatigueMismatch:
      return 'Your heart-rate recovery looks reasonable, but how you felt afterwards was lower than expected. That mismatch may reflect fatigue, stress, sleep or recovery factors outside the workout itself.';
  }
}

List<String> _choosePossibleReasons(
  RecoveryTrendSummary trend,
  String activity,
) {
  final reasons = <String>[];

  if ((trend.recentAverageEffort ?? 0) >= 7) {
    reasons.add('Higher-than-usual workout effort.');
  }

  if ((trend.recentAverageFeelingAfter ?? 10) <= 5) {
    reasons.add(
      'Lower post-workout feeling, which may reflect fatigue, sleep, hydration or stress.',
    );
  }

  if (trend.recoveryGapTrend == RecoveryGapTrend.widening) {
    reasons.add(
      'Delayed early recovery with stronger continued recovery into the second minute.',
    );
  }

  if (trend.recoveryGapTrend == RecoveryGapTrend.narrowing) {
    reasons.add(
      'Strong early recovery followed by less continued drop before 120 seconds.',
    );
  }

  if ((trend.recoveryVariability ?? 0) >= 10) {
    reasons.add('Variable test conditions or mixed workout types.');
  }

  if (activity == 'running') {
    reasons.add(
      'Running load can be affected by leg fatigue, hills, pace, heat and impact stress.',
    );
  } else if (activity == 'cycling') {
    reasons.add(
      'Cycling recovery can vary with resistance, cadence, climbs and sustained leg effort.',
    );
  } else if (activity == 'rowing') {
    reasons.add(
      'Rowing can add whole-body fatigue, especially through legs, trunk, back and grip.',
    );
  } else if (activity == 'hiit') {
    reasons.add(
      'HIIT often creates a stronger sympathetic load than steady aerobic work.',
    );
  }

  if (reasons.isEmpty) {
    reasons.add('Normal day-to-day variation in recovery response.');
  }

  return reasons.take(2).toList();
}

String _coachingFocus(
  RecoveryPatternDecision pattern,
  RecoveryTrendSummary trend,
  String activity,
  String activityModifier,
) {
  switch (pattern) {
    case RecoveryPatternDecision.improvingRecovery:
      return 'Keep your current training rhythm. Avoid increasing intensity and duration at the same time. $activityModifier';

    case RecoveryPatternDecision.stableRecovery:
      return 'Maintain consistency. If you want to improve recovery, add one easy aerobic session or slightly extend low-intensity work. $activityModifier';

    case RecoveryPatternDecision.recoveryUnderStrain:
      return 'Make the next session easier or shorter and check whether recovery rebounds. Avoid stacking another hard session immediately. $activityModifier';

    case RecoveryPatternDecision.slowStartStrongContinuation:
      return 'Focus on a smoother transition from exercise to recovery. Use a consistent cooldown and note whether this pattern follows harder sessions. $activityModifier';

    case RecoveryPatternDecision.fastStartThenStall:
      return 'Work on continued recovery beyond the first minute. Easy aerobic conditioning and a consistent cooldown may help. $activityModifier';

    case RecoveryPatternDecision.variableRecovery:
      return 'Standardise the test before changing training. Compare similar workouts, similar timing, and similar effort levels. $activityModifier';

    case RecoveryPatternDecision.hiddenLoad:
      return 'Treat this as an early caution signal. Keep the next session controlled and watch whether slower recovery appears before you feel tired. $activityModifier';

    case RecoveryPatternDecision.fatigueMismatch:
      return 'Prioritise recovery quality: sleep, hydration, nutrition and an easier aerobic session before adding intensity. $activityModifier';

    case RecoveryPatternDecision.buildingBaseline:
      return 'Build a clean baseline first. Repeat the test under similar conditions.';
  }
}

String _whatToTrackNext(
  RecoveryPatternDecision pattern,
  RecoveryTrendSummary trend,
  String activity,
) {
  switch (pattern) {
    case RecoveryPatternDecision.improvingRecovery:
      return 'Watch whether the improvement holds over your next 3 assessments, especially if workout effort increases.';

    case RecoveryPatternDecision.stableRecovery:
      return 'Track whether your baseline shifts over the next 3 similar workouts. Small changes matter more when conditions are consistent.';

    case RecoveryPatternDecision.recoveryUnderStrain:
      return 'Check whether recovery improves after an easier day or rest day. If it does, accumulated load was probably part of the picture.';

    case RecoveryPatternDecision.slowStartStrongContinuation:
      return 'Watch whether the 60s-to-120s gap stays wide after hard sessions, hot conditions, poor sleep or high-effort workouts.';

    case RecoveryPatternDecision.fastStartThenStall:
      return 'Watch whether your recovery repeatedly drops quickly in the first minute and then plateaus before 120 seconds.';

    case RecoveryPatternDecision.variableRecovery:
      return 'Compare like with like: same activity, similar duration, similar effort and similar recovery timing.';

    case RecoveryPatternDecision.hiddenLoad:
      return 'Track whether slower recovery appears before you feel tired. That could make this a useful early warning signal.';

    case RecoveryPatternDecision.fatigueMismatch:
      return 'Track sleep, hydration, soreness and stress alongside your next few recovery scores.';

    case RecoveryPatternDecision.buildingBaseline:
      return 'Complete at least 3 assessments using similar timing after exercise.';
  }
}

String _activityModifier(
  String activity,
  RecoveryPatternDecision pattern,
) {
  switch (activity) {
    case 'running':
      return 'For running, also watch leg fatigue, hills, pace and recovery between harder run days. Lower-body strength work such as calf raises, glute bridges or split squats may help resilience, but keep it progressive.';

    case 'cycling':
      return 'For cycling, compare similar cadence and resistance. If recovery is slipping, favour steady aerobic rides before adding more high-resistance work.';

    case 'rowing':
      return 'For rowing, monitor whole-body fatigue. Core stability, posterior-chain endurance and technique consistency may matter as much as pure fitness.';

    case 'strength':
      return 'For strength sessions, interpret HR recovery cautiously because muscular load and session density can drive fatigue even when aerobic demand is lower.';

    case 'hiit':
      return 'For HIIT, compare only with similar HIIT sessions. Avoid using a hard interval result as if it were the same as a steady aerobic workout.';

    case 'walking':
      return 'For walking, focus on gradually extending duration or consistency rather than intensity.';

    default:
      return 'Compare this result with similar workouts rather than mixing very different activity types.';
  }
}

String _confidenceText(RecoveryTrendSummary trend) {
  if (trend.assessmentCount < 3) {
    return 'Low confidence: not enough assessments yet.';
  }

  if (trend.assessmentCount < 6) {
    return 'Moderate confidence: early trend based on a small number of assessments.';
  }

  if ((trend.recoveryVariability ?? 0) >= 10) {
    return 'Moderate confidence: your results are variable, so compare similar workouts before drawing strong conclusions.';
  }

  if (trend.stalledPatternCountLast5 >= 3 ||
      trend.recoveryGapTrend != RecoveryGapTrend.stable) {
    return 'Higher confidence: this pattern is visible in your recent data.';
  }

  return 'Moderate confidence: based on your recent recovery baseline.';
}