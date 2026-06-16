import '../models/recovery_session_insight.dart';

class RecoveryBaselineComparator {
  static BaselineComparisonResult compare({
    required double currentRecoveryPercent120,
    required List<Map<String, dynamic>> recentAssessments,
    int baselineWindow = 5,
  }) {
    final previous = recentAssessments.take(baselineWindow).toList();

    if (previous.isEmpty) {
      return const BaselineComparisonResult(
        previousSessionCount: 0,
        hasEnoughHistory: false,
        recentAverageRecoveryPercent120: null,
        currentVsBaselineChange: null,
        trendLabel: 'first_session',
        message: 'First recovery baseline recorded.',
      );
    }

    final recoveryValues = previous
        .map((assessment) => _toDouble(assessment['recoveryPercent120']))
        .whereType<double>()
        .toList();

    if (recoveryValues.isEmpty) {
      return BaselineComparisonResult(
        previousSessionCount: previous.length,
        hasEnoughHistory: false,
        recentAverageRecoveryPercent120: null,
        currentVsBaselineChange: null,
        trendLabel: 'baseline_building',
        message: 'Your recovery baseline is still being built.',
      );
    }

    final average = recoveryValues.reduce((a, b) => a + b) / recoveryValues.length;
    final change = currentRecoveryPercent120 - average;

    if (previous.length < baselineWindow) {
      return BaselineComparisonResult(
        previousSessionCount: previous.length,
        hasEnoughHistory: false,
        recentAverageRecoveryPercent120: average,
        currentVsBaselineChange: change,
        trendLabel: 'baseline_building',
        message:
            'Early baseline forming. Your recovery was ${_changeText(change)} your current average.',
      );
    }

    if (change >= 5.0) {
      return BaselineComparisonResult(
        previousSessionCount: previous.length,
        hasEnoughHistory: true,
        recentAverageRecoveryPercent120: average,
        currentVsBaselineChange: change,
        trendLabel: 'better_than_usual',
        message:
            'Your 120-second recovery was ${change.toStringAsFixed(1)} percentage points above your recent average.',
      );
    }

    if (change <= -5.0) {
      return BaselineComparisonResult(
        previousSessionCount: previous.length,
        hasEnoughHistory: true,
        recentAverageRecoveryPercent120: average,
        currentVsBaselineChange: change,
        trendLabel: 'lower_than_usual',
        message:
            'Your 120-second recovery was ${change.abs().toStringAsFixed(1)} percentage points below your recent average.',
      );
    }

    return BaselineComparisonResult(
      previousSessionCount: previous.length,
      hasEnoughHistory: true,
      recentAverageRecoveryPercent120: average,
      currentVsBaselineChange: change,
      trendLabel: 'stable',
      message: 'Your recovery was close to your recent baseline.',
    );
  }

  static String _changeText(double change) {
    if (change >= 5.0) return 'above';
    if (change <= -5.0) return 'below';
    return 'close to';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}