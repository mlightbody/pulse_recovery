import '../models/recovery_input.dart';
import '../models/recovery_metrics.dart';

double clamp01(double value) {
  if (value < 0.0) return 0.0;
  if (value > 1.0) return 1.0;
  return value;
}

class RecoveryMetricsCalculator {
  static RecoveryMetrics calculate(RecoveryInput input) {
    final hrr60 = input.peakHr - input.hr60;
    final hrr120 = input.peakHr - input.hr120;
    final secondMinuteDrop = input.hr60 - input.hr120;

    final hrr60Percent = hrr60 / input.peakHr;
    final hrr120Percent = hrr120 / input.peakHr;

    final secondMinuteRatio =
        hrr60 > 0 ? secondMinuteDrop / hrr60 : null;

    final score60 = clamp01(hrr60 / 40.0);
    final score120 = clamp01(hrr120 / 60.0);

    final hrrScore = clamp01((score60 * 0.6) + (score120 * 0.4));

    return RecoveryMetrics(
      hrr60: hrr60,
      hrr120: hrr120,
      hrr60Percent: hrr60Percent,
      hrr120Percent: hrr120Percent,
      secondMinuteDrop: secondMinuteDrop,
      secondMinuteRatio: secondMinuteRatio,
      hrrScore: hrrScore,
    );
  }
}