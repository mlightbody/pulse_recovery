import '../models/recovery_session_insight.dart';

class RecoverySessionInsightBuilder {
  static DailyInsightResult build({
    required int peakHr,
    required int hr60,
    required int hr120,
    required int rpe,
    required int feelingAfter,
    required String recoveryPatternLabel,
    required DataQualityResult dataQuality,
    required BaselineComparisonResult baseline,
  }) {
    final mainHeadline = _mainHeadline(
      dataQuality: dataQuality,
      baseline: baseline,
    );

    final dailySignal = _dailySignal(
      dataQuality: dataQuality,
      baseline: baseline,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    final patternContext = _patternContext(recoveryPatternLabel);

    final coachingFocus = _coachingFocus(
      dataQuality: dataQuality,
      baseline: baseline,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    final badges = _badges(
      dataQuality: dataQuality,
      baseline: baseline,
      recoveryPatternLabel: recoveryPatternLabel,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    return DailyInsightResult(
      mainHeadline: mainHeadline,
      dailySignal: dailySignal,
      patternContext: patternContext,
      baselineMessage: baseline.message,
      coachingFocus: coachingFocus,
      dataConfidenceLabel: dataQuality.confidenceLabel,
      dataQualityMessage: dataQuality.message,
      badges: badges,
    );
  }

  static String _mainHeadline({
    required DataQualityResult dataQuality,
    required BaselineComparisonResult baseline,
  }) {
    if (!dataQuality.hrrReliable) {
      return 'Recovery data was incomplete today';
    }

    switch (baseline.trendLabel) {
      case 'better_than_usual':
        return 'Recovery was better than your recent baseline';
      case 'lower_than_usual':
        return 'Recovery was lower than your recent baseline';
      case 'stable':
        return 'Recovery looks normal for you today';
      case 'first_session':
        return 'First recovery baseline recorded';
      default:
        return 'Recovery baseline is building';
    }
  }

  static String _dailySignal({
    required DataQualityResult dataQuality,
    required BaselineComparisonResult baseline,
    required int rpe,
    required int feelingAfter,
  }) {
    if (!dataQuality.hrrReliable) {
      return 'The most useful signal today is data quality: repeat the test with a snug watch fit before drawing strong conclusions.';
    }

    if (!baseline.hasEnoughHistory) {
      return 'You are still building your personal recovery baseline. Consistent test conditions matter more than one result.';
    }

    if (baseline.trendLabel == 'better_than_usual') {
      return 'Your 120-second recovery was stronger than your recent average.';
    }

    if (baseline.trendLabel == 'lower_than_usual') {
      return 'Your 120-second recovery was weaker than your recent average.';
    }

    if (rpe >= 8 && feelingAfter >= 7) {
      return 'You worked hard but still felt reasonably good afterwards.';
    }

    if (rpe <= 5 && feelingAfter <= 5) {
      return 'The workout did not feel very hard, but you did not feel especially fresh afterwards.';
    }

    return 'No major change today — your recovery looks consistent with your recent baseline.';
  }

  static String _patternContext(String recoveryPatternLabel) {
    if (recoveryPatternLabel.trim().isEmpty) {
      return 'Recovery pattern was not available for this assessment.';
    }

    return 'Your recovery pattern today was: $recoveryPatternLabel. Treat this as your recovery style, not the whole result.';
  }

  static String _coachingFocus({
    required DataQualityResult dataQuality,
    required BaselineComparisonResult baseline,
    required int rpe,
    required int feelingAfter,
  }) {
    if (!dataQuality.hrrReliable) {
      return 'Focus today: improve measurement quality. Tighten the watch and repeat after a similar effort.';
    }

    if (!baseline.hasEnoughHistory) {
      return 'Focus today: keep collecting consistent sessions so the app can build your personal baseline.';
    }

    if (baseline.trendLabel == 'lower_than_usual') {
      return 'Focus today: consider an easier next session, especially if sleep, soreness or stress are also poor.';
    }

    if (rpe >= 8 && feelingAfter <= 5) {
      return 'Focus today: watch for accumulated fatigue. Hard effort plus poor post-workout feeling is worth tracking.';
    }

    if (baseline.trendLabel == 'better_than_usual') {
      return 'Focus today: maintain the current rhythm. Avoid increasing intensity and duration at the same time.';
    }

    return 'Focus today: consistency. Your recovery is not showing a major warning sign.';
  }

  static List<String> _badges({
    required DataQualityResult dataQuality,
    required BaselineComparisonResult baseline,
    required String recoveryPatternLabel,
    required int rpe,
    required int feelingAfter,
  }) {
    final badges = <String>[];

    if (dataQuality.hrrReliable) {
      badges.add('Usable recovery data');
    } else {
      badges.add('Check sensor fit');
    }

    if (baseline.trendLabel == 'stable') {
      badges.add('Stable baseline');
    } else if (baseline.trendLabel == 'better_than_usual') {
      badges.add('Above baseline');
    } else if (baseline.trendLabel == 'lower_than_usual') {
      badges.add('Below baseline');
    } else {
      badges.add('Baseline building');
    }

    if (recoveryPatternLabel.toLowerCase().contains('sustained')) {
      badges.add('Sustained recovery');
    } else if (recoveryPatternLabel.toLowerCase().contains('stall')) {
      badges.add('Early drop pattern');
    }

    if (rpe >= 8) {
      badges.add('Hard effort');
    }

    if (feelingAfter >= 8) {
      badges.add('Felt fresh after');
    }

    return badges.take(4).toList();
  }
}