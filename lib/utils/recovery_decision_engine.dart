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

enum _SessionRecoveryPattern {
  strongRecovery,
  strongStartLimitedFollowThrough,
  slowStartBetterSecondMinute,
  highStrain,
  hiddenLoad,
  fatigueMismatch,
  easySessionHandledWell,
  weakRecovery,
  normalResponse,
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

class _AdviceParts {
  final String recoveryTypeTitle;
  final String recoveryPatternDetail;
  final String testInterpretation;
  final String trainingFocus;
  final String specificSession;
  final String measurableTarget;
  final String responseWindow;
  final String progressRule;
  final String holdBackRule;

  const _AdviceParts({
    required this.recoveryTypeTitle,
    required this.recoveryPatternDetail,
    required this.testInterpretation,
    required this.trainingFocus,
    required this.specificSession,
    required this.measurableTarget,
    required this.responseWindow,
    required this.progressRule,
    required this.holdBackRule,
  });

  String get combinedRecommendation {
    return 'Training focus: $trainingFocus\n\n'
        'Try this: $specificSession\n\n'
        'Measure this: $measurableTarget\n\n'
        'Response window: $responseWindow';
  }
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

  final expectedRecovery = clamp01(1.0 - rpeScore);
  final recoveryGap = metrics.hrrScore - expectedRecovery;
  final fatigueSignal = 1.0 - feelingScore;

  final firstMinuteDrop = peakHr - hr60;
  final secondMinuteDrop = hr60 - hr120;
  final totalDrop = peakHr - hr120;
  final totalDropPercent = peakHr > 0 ? totalDrop / peakHr : 0.0;

  final pattern = _classifySessionPattern(
    peakHr: peakHr,
    hr60: hr60,
    hr120: hr120,
    rpe: rpe,
    feelingAfter: feelingAfter,
    firstMinuteDrop: firstMinuteDrop,
    secondMinuteDrop: secondMinuteDrop,
    totalDrop: totalDrop,
    totalDropPercent: totalDropPercent,
  );

  final advice = _adviceForPattern(
    pattern: pattern,
    peakHr: peakHr,
    hr60: hr60,
    hr120: hr120,
    rpe: rpe,
    feelingAfter: feelingAfter,
    firstMinuteDrop: firstMinuteDrop,
    secondMinuteDrop: secondMinuteDrop,
    totalDrop: totalDrop,
    totalDropPercent: totalDropPercent,
  );

  final reasonTag = _reasonTagForPattern(pattern, decision.reasonTag);
  final state = _stateForPattern(pattern, decision.state);

  return RecoveryDecisionResult(
    state: state,
    reasonTag: reasonTag,
    title: advice.recoveryTypeTitle,
    summary: advice.testInterpretation,
    recommendation: advice.combinedRecommendation,
    recoveryTypeTitle: advice.recoveryTypeTitle,
    recoveryPatternDetail: advice.recoveryPatternDetail,
    testInterpretation: advice.testInterpretation,
    trainingFocus: advice.trainingFocus,
    specificSession: advice.specificSession,
    measurableTarget: advice.measurableTarget,
    responseWindow: advice.responseWindow,
    progressRule: advice.progressRule,
    holdBackRule: advice.holdBackRule,
    hrrScore: metrics.hrrScore,
    rpeScore: rpeScore,
    feelingScore: feelingScore,
    expectedRecovery: expectedRecovery,
    recoveryGap: recoveryGap,
    fatigueSignal: fatigueSignal,
  );
}

_SessionRecoveryPattern _classifySessionPattern({
  required int peakHr,
  required int hr60,
  required int hr120,
  required int rpe,
  required int feelingAfter,
  required int firstMinuteDrop,
  required int secondMinuteDrop,
  required int totalDrop,
  required double totalDropPercent,
}) {
  final hardSession = rpe >= 7;
  final veryHardSession = rpe >= 8;
  final feltPoorAfter = feelingAfter <= 4;
  final feltGoodAfter = feelingAfter >= 7;
  final lowTotalRecovery = totalDrop < 22 || totalDropPercent < 0.15;
  final strongFirstMinute = firstMinuteDrop >= 30;
  final moderateFirstMinute = firstMinuteDrop >= 18;
  final weakFirstMinute = firstMinuteDrop < 18;
  final usefulSecondMinute = secondMinuteDrop >= 10;
  final limitedSecondMinute = secondMinuteDrop <= 6;
  final strongTotalRecovery = totalDrop >= 45 || totalDropPercent >= 0.30;

  if (veryHardSession && feltPoorAfter && lowTotalRecovery) {
    return _SessionRecoveryPattern.highStrain;
  }

  if (hardSession && feltPoorAfter && totalDrop < 30) {
    return _SessionRecoveryPattern.highStrain;
  }

  if (feltGoodAfter && lowTotalRecovery) {
    return _SessionRecoveryPattern.hiddenLoad;
  }

  if (!lowTotalRecovery && feltPoorAfter) {
    return _SessionRecoveryPattern.fatigueMismatch;
  }

  if (strongFirstMinute && limitedSecondMinute) {
    return _SessionRecoveryPattern.strongStartLimitedFollowThrough;
  }

  if (weakFirstMinute && usefulSecondMinute) {
    return _SessionRecoveryPattern.slowStartBetterSecondMinute;
  }

  if (strongTotalRecovery && moderateFirstMinute && usefulSecondMinute) {
    return _SessionRecoveryPattern.strongRecovery;
  }

  if (rpe <= 4 && totalDrop >= 30 && feltGoodAfter) {
    return _SessionRecoveryPattern.easySessionHandledWell;
  }

  if (lowTotalRecovery) {
    return _SessionRecoveryPattern.weakRecovery;
  }

  return _SessionRecoveryPattern.normalResponse;
}

RecoveryReasonTag _reasonTagForPattern(
  _SessionRecoveryPattern pattern,
  RecoveryReasonTag fallback,
) {
  switch (pattern) {
    case _SessionRecoveryPattern.strongRecovery:
      return RecoveryReasonTag.strongRecovery;
    case _SessionRecoveryPattern.strongStartLimitedFollowThrough:
      return RecoveryReasonTag.normalResponse;
    case _SessionRecoveryPattern.slowStartBetterSecondMinute:
      return RecoveryReasonTag.normalResponse;
    case _SessionRecoveryPattern.highStrain:
      return RecoveryReasonTag.highStrain;
    case _SessionRecoveryPattern.hiddenLoad:
      return RecoveryReasonTag.hiddenLoad;
    case _SessionRecoveryPattern.fatigueMismatch:
      return RecoveryReasonTag.fatigueMismatch;
    case _SessionRecoveryPattern.easySessionHandledWell:
      return RecoveryReasonTag.easySessionHandledWell;
    case _SessionRecoveryPattern.weakRecovery:
      return RecoveryReasonTag.weakRecovery;
    case _SessionRecoveryPattern.normalResponse:
      return fallback;
  }
}

RecoveryDecisionState _stateForPattern(
  _SessionRecoveryPattern pattern,
  RecoveryDecisionState fallback,
) {
  switch (pattern) {
    case _SessionRecoveryPattern.strongRecovery:
      return RecoveryDecisionState.progress;
    case _SessionRecoveryPattern.strongStartLimitedFollowThrough:
      return RecoveryDecisionState.maintain;
    case _SessionRecoveryPattern.slowStartBetterSecondMinute:
      return RecoveryDecisionState.maintain;
    case _SessionRecoveryPattern.highStrain:
      return RecoveryDecisionState.recover;
    case _SessionRecoveryPattern.hiddenLoad:
      return RecoveryDecisionState.caution;
    case _SessionRecoveryPattern.fatigueMismatch:
      return RecoveryDecisionState.caution;
    case _SessionRecoveryPattern.easySessionHandledWell:
      return RecoveryDecisionState.maintain;
    case _SessionRecoveryPattern.weakRecovery:
      return RecoveryDecisionState.caution;
    case _SessionRecoveryPattern.normalResponse:
      return fallback;
  }
}

_AdviceParts _adviceForPattern({
  required _SessionRecoveryPattern pattern,
  required int peakHr,
  required int hr60,
  required int hr120,
  required int rpe,
  required int feelingAfter,
  required int firstMinuteDrop,
  required int secondMinuteDrop,
  required int totalDrop,
  required double totalDropPercent,
}) {
  final percentText = (totalDropPercent * 100).toStringAsFixed(1);

  switch (pattern) {
    case _SessionRecoveryPattern.strongRecovery:
      return _AdviceParts(
        recoveryTypeTitle: 'Strong recovery response',
        recoveryPatternDetail:
            'Your heart rate dropped well in the first minute and continued to fall into the second minute.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). Given the effort and how you felt afterwards, this looks like a good recovery result for this test.',
        trainingFocus:
            'Progress carefully. Keep the recovery quality while adding only one training stress at a time.',
        specificSession:
            'For the next 4 weeks, keep 2 easy aerobic sessions each week and add 1 quality session: 8-10 rounds of 1 minute hard followed by 1 minute easy walking. Keep the hard minute around 8/10 effort, not an all-out sprint.',
        measurableTarget:
            'Retest weekly after a similar workout. Aim to maintain or improve the 120-second drop while the workout feels no harder, or lower your 120-second heart rate by 3-5 bpm.',
        responseWindow:
            'Use 2 weeks as an early check. Judge real progress after 4 weeks and 3-4 comparable tests.',
        progressRule:
            'Progress by adding 1-2 reps or slightly extending an easy session only if recovery remains stable.',
        holdBackRule:
            'Do not increase both workout intensity and duration in the same week.',
      );

    case _SessionRecoveryPattern.strongStartLimitedFollowThrough:
      return _AdviceParts(
        recoveryTypeTitle: 'Strong start, limited follow-through',
        recoveryPatternDetail:
            'Your early recovery was strong, but the second minute added relatively little extra drop.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). The useful target is not just the first-minute drop; it is improving the continued recovery between 60 and 120 seconds.',
        trainingFocus:
            'Build sustained recovery after the first minute without making the session maximal.',
        specificSession:
            'For the next 4 weeks, do 1-2 interval sessions per week: 8 rounds of 1 minute hard, then 1 minute easy walking. If recovery remains stable after 2 weeks, progress to 10 rounds. Keep at least 48 hours between hard sessions.',
        measurableTarget:
            'Retest weekly after a similar workout. Aim to improve the second-minute drop by 2-3 bpm, or lower your 120-second heart rate by 3-5 bpm.',
        responseWindow:
            'Expect noise after 2 weeks. A realistic response window is 4-6 weeks.',
        progressRule:
            'Add reps before adding intensity. Keep the hard reps controlled at about 8/10 effort.',
        holdBackRule:
            'If your 120-second heart rate rises or your post-workout feeling drops below 6/10, hold the number of reps steady or reduce the next session.',
      );

    case _SessionRecoveryPattern.slowStartBetterSecondMinute:
      return _AdviceParts(
        recoveryTypeTitle: 'Slow start, better second minute',
        recoveryPatternDetail:
            'Your recovery started more slowly, then improved meaningfully in the second minute.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). Recovery was delayed rather than absent.',
        trainingFocus:
            'Improve the early transition from hard effort to recovery, mainly through aerobic base work and a calmer cooldown.',
        specificSession:
            'For the next 4-6 weeks, add 2-3 easy aerobic sessions per week of 25-45 minutes at conversational pace. After harder workouts, finish with 5 minutes very easy movement before starting the recovery test.',
        measurableTarget:
            'Retest weekly after a similar workout. Aim for the first-minute drop to improve by 3-5 bpm without making the workout feel harder.',
        responseWindow:
            'Use 4 weeks for an early training response. Use 6 weeks before deciding whether the pattern has really changed.',
        progressRule:
            'Extend easy duration by 5 minutes before adding intensity.',
        holdBackRule:
            'Avoid adding extra intervals until the first-minute recovery becomes more consistent.',
      );

    case _SessionRecoveryPattern.highStrain:
      return _AdviceParts(
        recoveryTypeTitle: 'High strain signal',
        recoveryPatternDetail:
            'Recovery was limited and your post-workout feeling was low, especially relative to the effort.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). Both the recovery numbers and your post-workout feeling suggest this session placed a high load on you.',
        trainingFocus:
            'Reduce strain before adding intensity. The immediate goal is recovery rebound, not progression.',
        specificSession:
            'For the next 7-10 days, make sessions easier or shorter. Use easy aerobic work of 20-35 minutes at conversational pace and avoid hard intervals. Then repeat a similar controlled test.',
        measurableTarget:
            'Aim for your 120-second heart rate to be 3-5 bpm lower after a similar workout, or for your feeling-after score to improve by at least 2 points.',
        responseWindow:
            'A rebound can show within 3-10 days. Do not judge fitness gain until you have 3-4 comparable tests over 4 weeks.',
        progressRule:
            'Resume intensity only after recovery and post-workout feeling return to normal.',
        holdBackRule:
            'If this pattern repeats, take another easier block rather than pushing through.',
      );

    case _SessionRecoveryPattern.hiddenLoad:
      return _AdviceParts(
        recoveryTypeTitle: 'Possible hidden load',
        recoveryPatternDetail:
            'You felt okay, but the heart-rate recovery was weaker than expected.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). This can happen when load is building before it is obvious subjectively.',
        trainingFocus:
            'Treat this as a caution signal. Keep training controlled and check whether recovery rebounds.',
        specificSession:
            'For the next 3-7 days, keep sessions easy to moderate. Use 25-40 minutes conversational aerobic work, or reduce the next interval session by 20-30%.',
        measurableTarget:
            'Retest after an easier day. Aim for the 120-second drop to improve by 3-5 bpm or return to your usual range.',
        responseWindow:
            'This should be checked within 1 week. If it persists for 2-3 tests, treat it as accumulated load.',
        progressRule:
            'Progress only when both recovery and subjective feeling agree.',
        holdBackRule:
            'Do not add another hard session while recovery is weak, even if you feel okay.',
      );

    case _SessionRecoveryPattern.fatigueMismatch:
      return _AdviceParts(
        recoveryTypeTitle: 'Recovery mismatch',
        recoveryPatternDetail:
            'Your heart-rate recovery looked acceptable, but you did not feel good afterwards.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). The heart-rate result is not the whole story; your lower feeling score may reflect fatigue, sleep, stress, soreness or fuelling.',
        trainingFocus:
            'Improve recovery quality before chasing harder sessions.',
        specificSession:
            'For the next 3-7 days, use one easy aerobic session of 20-35 minutes and avoid maximal intervals. Prioritise sleep, hydration and food before the next hard effort.',
        measurableTarget:
            'Retest after a lighter day. Aim for your feeling-after score to improve by 1-2 points without the 120-second recovery getting worse.',
        responseWindow:
            'Subjective recovery can change within days. Use 2-3 tests before changing the training plan.',
        progressRule:
            'Return to normal training when feeling-after is 7/10 or better and recovery remains stable.',
        holdBackRule:
            'If you repeatedly feel poor despite reasonable HR recovery, keep the advice conservative.',
      );

    case _SessionRecoveryPattern.easySessionHandledWell:
      return _AdviceParts(
        recoveryTypeTitle: 'Easy session handled well',
        recoveryPatternDetail:
            'Your recovery was good, but the workout may not have been demanding enough to say much about fitness progression.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). This is reassuring, but an easy session is mainly a baseline check.',
        trainingFocus:
            'Build a cleaner baseline using a repeatable moderate test.',
        specificSession:
            'Use a standard test once per week: 20-30 minutes at moderate conversational effort, then record the 2-minute recovery. Keep the route, machine, resistance or pace as similar as possible.',
        measurableTarget:
            'Aim to compare like with like. Do not chase a big improvement from a very easy test.',
        responseWindow:
            'You can create a useful baseline in 2-3 weeks. Judge change after at least 3 comparable tests.',
        progressRule:
            'Once baseline is stable, add either 5 minutes easy duration or one controlled quality session each week.',
        holdBackRule:
            'Avoid interpreting easy-session recovery as proof that hard-session recovery is ready to progress.',
      );

    case _SessionRecoveryPattern.weakRecovery:
      return _AdviceParts(
        recoveryTypeTitle: 'Weak recovery response',
        recoveryPatternDetail:
            'Your heart rate did not fall much over the two-minute recovery window.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). This suggests the next step should be controlled aerobic work rather than more intensity.',
        trainingFocus:
            'Build aerobic recovery capacity and reduce the chance of stacking fatigue.',
        specificSession:
            'For the next 4 weeks, do 2-3 easy aerobic sessions per week of 25-40 minutes at conversational pace. Keep hard intervals out until recovery improves.',
        measurableTarget:
            'Retest weekly after a similar workout. Aim to lower your 120-second heart rate by 3-5 bpm or improve total 120-second drop by 3-5 bpm.',
        responseWindow:
            'Use 4 weeks for the first meaningful check. Use 6-8 weeks for a more reliable trend.',
        progressRule:
            'Increase easy duration gradually before adding hard work.',
        holdBackRule:
            'If recovery remains weak and you feel unwell, dizzy, unusually breathless, or have chest discomfort, stop testing and seek medical advice.',
      );

    case _SessionRecoveryPattern.normalResponse:
      return _AdviceParts(
        recoveryTypeTitle: 'Normal recovery response',
        recoveryPatternDetail:
            'Your recovery pattern is within a usable range for this test, without a strong warning signal.',
        testInterpretation:
            'Your heart rate dropped $firstMinuteDrop bpm in the first minute and another $secondMinuteDrop bpm in the second minute, for a total 120-second drop of $totalDrop bpm ($percentText%). This is most useful as part of a trend rather than as a single result.',
        trainingFocus:
            'Build consistency and compare similar sessions.',
        specificSession:
            'For the next 4 weeks, complete 2 easy aerobic sessions of 25-40 minutes and 1 controlled quality session each week. For quality work, use 6-8 rounds of 1 minute hard and 1 minute easy.',
        measurableTarget:
            'Retest weekly after a similar workout. Aim for either a 3-5 bpm lower 120-second heart rate or the same recovery after a slightly harder session.',
        responseWindow:
            'Judge progress after 3-4 comparable tests over about 4 weeks.',
        progressRule:
            'Progress one variable at a time: duration, reps or intensity.',
        holdBackRule:
            'If effort rises but recovery worsens, hold the training load steady for another week.',
      );
  }
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
      return 'Maintain consistency. To improve fitness, increase training load gradually and monitor whether recovery remains stable. Use easy aerobic sessions to support recovery between harder workouts. $activityModifier';

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
      return 'For running, also watch leg fatigue, hills, pace and recovery between harder run days. Lower-body strength work can help resilience, but keep it progressive.';

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