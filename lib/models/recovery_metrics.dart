class RecoveryMetrics {
  final int hrr60;
  final int hrr120;
  final double hrr60Percent;
  final double hrr120Percent;
  final int secondMinuteDrop;
  final double? secondMinuteRatio;
  final double hrrScore;

  const RecoveryMetrics({
    required this.hrr60,
    required this.hrr120,
    required this.hrr60Percent,
    required this.hrr120Percent,
    required this.secondMinuteDrop,
    required this.secondMinuteRatio,
    required this.hrrScore,
  });

  double get recoveryPercent120 => hrr120Percent * 100.0;

  double get recoveryGapPercent => (hrr120Percent - hrr60Percent) * 100.0;
}