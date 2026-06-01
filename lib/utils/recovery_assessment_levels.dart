import 'recovery_rules.dart';

String classifyEarlyRecovery(
  int hrr60, {
  RecoveryThresholds thresholds = defaultRecoveryThresholds,
}) {
  for (final band in thresholds.earlyRecoveryBands) {
    if (hrr60 < band.upperExclusive) {
      return band.label;
    }
  }

  return 'Excellent';
}

String classifyOverallRecovery(
  int hrr120, {
  RecoveryThresholds thresholds = defaultRecoveryThresholds,
}) {
  for (final band in thresholds.overallRecoveryBands) {
    if (hrr120 < band.upperExclusive) {
      return band.label;
    }
  }

  return 'Excellent';
}