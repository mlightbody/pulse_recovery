class RecoveryBand {
  const RecoveryBand({
    required this.label,
    required this.upperExclusive,
  });

  final String label;
  final int upperExclusive;
}

class RecoveryThresholds {
  const RecoveryThresholds({
    required this.earlyRecoveryBands,
    required this.overallRecoveryBands,
    required this.weakDrop1,
    required this.weakDrop2,
    required this.naturalFlatteningHr120,
    required this.excellentEarlyDrop,
    required this.goodTotalDrop,
    required this.fastStartDrop,
    required this.stalledSecondPhaseDrop,
    required this.elevatedHr120,
    required this.veryElevatedHr120,
    required this.sustainedRatioMin,
    required this.delayedRatioMin,
    required this.delayedMinimumExtraDrop,
  });

  final List<RecoveryBand> earlyRecoveryBands;
  final List<RecoveryBand> overallRecoveryBands;

  final int weakDrop1;
  final int weakDrop2;

  final int naturalFlatteningHr120;
  final int excellentEarlyDrop;
  final int goodTotalDrop;

  final int fastStartDrop;
  final int stalledSecondPhaseDrop;
  final int elevatedHr120;
  final int veryElevatedHr120;

  final double sustainedRatioMin;
  final double delayedRatioMin;
  final int delayedMinimumExtraDrop;
}

const defaultRecoveryThresholds = RecoveryThresholds(
  earlyRecoveryBands: [
    RecoveryBand(label: 'Low', upperExclusive: 12),
    RecoveryBand(label: 'Moderate', upperExclusive: 20),
    RecoveryBand(label: 'Good', upperExclusive: 30),
  ],
  overallRecoveryBands: [
    RecoveryBand(label: 'Poor', upperExclusive: 22),
    RecoveryBand(label: 'Fair', upperExclusive: 35),
    RecoveryBand(label: 'Average', upperExclusive: 45),
    RecoveryBand(label: 'Good', upperExclusive: 60),
  ],

  weakDrop1: 8,
  weakDrop2: 5,

  naturalFlatteningHr120: 90,
  excellentEarlyDrop: 40,
  goodTotalDrop: 50,

  fastStartDrop: 30,
  stalledSecondPhaseDrop: 10,
  elevatedHr120: 100,
  veryElevatedHr120: 120,

  sustainedRatioMin: 0.5,
  delayedRatioMin: 1.0,
  delayedMinimumExtraDrop: 5,
);