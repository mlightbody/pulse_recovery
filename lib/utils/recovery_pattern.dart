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
}) {
  final drop1 = peakHr - hr60;
  final drop2 = hr60 - hr120;

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

  if (drop1 < 8 && drop2 < 5) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: drop2 / drop1,
      label: 'Weak recovery',
      description:
          'Heart rate fell only slightly across both recovery phases.',
      shortAdvice:
          'This may suggest fatigue, stress, poor recovery, or insufficient test effort.',
    );
  }

  final ratio = drop2 / drop1;

  if (ratio < 0.5) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Fast start, then stall',
      description:
          'Heart rate dropped well in the first minute, but recovery slowed in the second minute.',
      shortAdvice:
          'This may suggest good initial recovery but incomplete follow-through.',
    );
  }

  if (ratio >= 0.5 && ratio <= 1.2) {
    return RecoveryPatternResult(
      drop1: drop1,
      drop2: drop2,
      ratio: ratio,
      label: 'Sustained recovery',
      description:
          'Heart rate continued to fall steadily across both recovery phases.',
      shortAdvice:
          'This is generally a positive recovery pattern.',
    );
  }

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