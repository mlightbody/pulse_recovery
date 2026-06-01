import 'recovery_rules.dart';

class RecoveryPatternResult {
  final int drop1;
  final int drop2;
  final double? ratio;
  final String label;
  final String description;
  final String shortAdvice;

  RecoveryPatternResult({
    required this.drop1,
    required this.drop2,
    required this.ratio,
    required this.label,
    required this.description,
    required this.shortAdvice,
  });
}

RecoveryPatternResult calculateRecoveryPattern({
  required int peakHr,
  required int hr60,
  required int hr120,
  RecoveryThresholds thresholds = defaultRecoveryThresholds,
}) {
  final drop1 = peakHr - hr60;
  final drop2 = hr60 - hr120;
  final totalDrop = peakHr - hr120;

  if (drop1 <= 0 || drop2 < 0) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: null,
      label: 'Unclear pattern',
      description:
          'The recovery values do not show a clear downward heart-rate pattern.',
      shortAdvice: 'Check the readings and repeat the test if needed.',
    );
  }

  final ratio = drop2 / drop1;

  if (drop1 < thresholds.weakDrop1 && drop2 < thresholds.weakDrop2) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Weak recovery',
      description: 'Heart rate fell only slightly across both recovery phases.',
      shortAdvice:
          'This may suggest fatigue, stress, poor recovery, or insufficient test effort.',
    );
  }

  final isNearRecoveryFloor = hr120 <= thresholds.naturalFlatteningHr120;
  final hasExcellentEarlyDrop = drop1 >= thresholds.excellentEarlyDrop;
  final hasGoodTotalDrop = totalDrop >= thresholds.goodTotalDrop;

  if (hasExcellentEarlyDrop && hasGoodTotalDrop && isNearRecoveryFloor) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Fast recovery with natural flattening',
      description:
          'Heart rate dropped quickly in the first minute and then levelled off near a low recovery value.',
      shortAdvice:
          'This looks like strong recovery. A smaller second-minute drop is expected when heart rate is already low.',
    );
  }

  // Important: check poor/slow overall recovery before looking for a
  // first-minute/second-minute pattern. If HR is still very high at 120s,
  // that should dominate the interpretation.
  final limitedOverallRecovery =
      totalDrop < thresholds.goodTotalDrop &&
      hr120 >= thresholds.veryElevatedHr120;

  if (limitedOverallRecovery) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Slow overall recovery',
      description:
          'Heart rate did fall, but it remained relatively high after two minutes.',
      shortAdvice:
          'This may reflect fatigue, stress, heat, dehydration, poor sleep, or a harder-than-usual effort.',
    );
  }

  final hasFastStart = drop1 >= thresholds.fastStartDrop;
  final hasSmallSecondPhaseDrop =
      drop2 <= thresholds.stalledSecondPhaseDrop;
  final remainsElevated = hr120 >= thresholds.elevatedHr120;

  if (hasFastStart && hasSmallSecondPhaseDrop && remainsElevated) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Fast start, then stall',
      description:
          'Heart rate dropped well in the first minute, but recovery slowed while heart rate remained relatively elevated.',
      shortAdvice:
          'This may suggest good initial recovery but incomplete follow-through.',
    );
  }

  final secondPhaseClearlyStronger =
      ratio > thresholds.delayedRatioMin &&
      (drop2 - drop1) >= thresholds.delayedMinimumExtraDrop;

  if (secondPhaseClearlyStronger) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Delayed recovery',
      description:
          'Heart rate dropped more strongly in the second minute than the first.',
      shortAdvice:
          'This may suggest slower initial recovery followed by useful catch-up.',
    );
  }

  if (ratio < thresholds.sustainedRatioMin) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Fast start, then natural slowing',
      description:
          'Heart rate dropped more strongly in the first minute, then slowed in the second minute.',
      shortAdvice:
          'This can be normal, especially if the two-minute heart rate is already reasonably low.',
    );
  }

  return RecoveryPatternResult(
    drop1: drop1,
    drop2: drop2,
    ratio: ratio,
    label: 'Sustained recovery',
    description:
        'Heart rate continued to fall steadily across both recovery phases.',
    shortAdvice: 'This is generally a positive recovery pattern.',
  );
}