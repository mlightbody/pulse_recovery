import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TrendDirection {
  improving,
  stable,
  declining,
  notEnoughData,
}

enum RecoveryGapTrend {
  widening,
  narrowing,
  stable,
  notEnoughData,
}

class RecoveryTrendSummary {
  const RecoveryTrendSummary({
    required this.assessmentCount,
    required this.trendDirection,
    this.latestRecoveryPercent120,
    this.recentAverageRecoveryPercent120,
    this.previousAverageRecoveryPercent120,
    this.changeVsPreviousAverage,
    this.latestHrr60,
    this.latestHrr120,
    this.latestHrr60Percent,
    this.latestHrr120Percent,
    this.recentAverageHrr60,
    this.recentAverageHrr120,
    this.recentAverageHrr60Percent,
    this.recentAverageHrr120Percent,
    this.latestRecoveryGapPercent,
    this.recentAverageRecoveryGapPercent,
    this.previousAverageRecoveryGapPercent,
    this.recoveryGapChangeVsRecentAverage,
    this.recoveryGapTrend = RecoveryGapTrend.notEnoughData,
    this.recentAveragePeakHr,
    this.recentAverageHr60,
    this.recentAverageHr120,
    this.recentAverageEffort,
    this.recentAverageFeelingAfter,
    this.mostCommonPatternLast5,
    this.stalledPatternCountLast5 = 0,
    this.excellentCountLast5 = 0,
    this.goodOrExcellentCountLast5 = 0,
    this.possibleFatigueMismatch = false,
    this.possibleHiddenLoadMismatch = false,
    this.subjectiveImproving = false,
    this.subjectiveDeclining = false,
    this.recoveryVariability,
    this.bestRecoveryPercent120,
    this.worstRecoveryPercent120,
    this.latestActivityType,
    this.mostCommonActivityType,
    this.activityTypeRecoveryAverages = const {},
  });

  final int assessmentCount;
  final TrendDirection trendDirection;

  final double? latestRecoveryPercent120;
  final double? recentAverageRecoveryPercent120;
  final double? previousAverageRecoveryPercent120;
  final double? changeVsPreviousAverage;

  final double? latestHrr60;
  final double? latestHrr120;
  final double? latestHrr60Percent;
  final double? latestHrr120Percent;

  final double? recentAverageHrr60;
  final double? recentAverageHrr120;
  final double? recentAverageHrr60Percent;
  final double? recentAverageHrr120Percent;

  /// Difference between cumulative 120s recovery % and cumulative 60s recovery %.
  /// This is the extra recovery gained during the second minute, expressed
  /// as a percentage of peak HR.
  final double? latestRecoveryGapPercent;
  final double? recentAverageRecoveryGapPercent;
  final double? previousAverageRecoveryGapPercent;
  final double? recoveryGapChangeVsRecentAverage;
  final RecoveryGapTrend recoveryGapTrend;

  final double? recentAveragePeakHr;
  final double? recentAverageHr60;
  final double? recentAverageHr120;

  final double? recentAverageEffort;
  final double? recentAverageFeelingAfter;

  final String? mostCommonPatternLast5;
  final int stalledPatternCountLast5;
  final int excellentCountLast5;
  final int goodOrExcellentCountLast5;

  final bool possibleFatigueMismatch;
  final bool possibleHiddenLoadMismatch;
  final bool subjectiveImproving;
  final bool subjectiveDeclining;

  final double? recoveryVariability;
  final double? bestRecoveryPercent120;
  final double? worstRecoveryPercent120;

  final String? latestActivityType;
  final String? mostCommonActivityType;
  final Map<String, double> activityTypeRecoveryAverages;

  bool get hasEnoughForTrend => assessmentCount >= 3;

  String get trendLabel {
    switch (trendDirection) {
      case TrendDirection.improving:
        return 'Improving';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.declining:
        return 'Declining';
      case TrendDirection.notEnoughData:
        return 'Not enough data yet';
    }
  }

  String get recoveryGapLabel {
    switch (recoveryGapTrend) {
      case RecoveryGapTrend.widening:
        return 'Late recovery strengthening';
      case RecoveryGapTrend.narrowing:
        return 'Early recovery dominant';
      case RecoveryGapTrend.stable:
        return 'Recovery timing stable';
      case RecoveryGapTrend.notEnoughData:
        return 'Not enough timing data yet';
    }
  }

  String get dashboardSummary {
    if (trendDirection == TrendDirection.notEnoughData) {
      return 'Complete at least 3 assessments to start seeing meaningful recovery trends.';
    }

    final change = changeVsPreviousAverage;
    if (change == null) {
      return 'Recovery trend is being calculated from your recent assessments.';
    }

    final absChange = change.abs().toStringAsFixed(1);

    switch (trendDirection) {
      case TrendDirection.improving:
        return 'Your 120-second recovery is improving by about $absChange percentage points versus your previous baseline.';
      case TrendDirection.declining:
        return 'Your 120-second recovery is down by about $absChange percentage points versus your previous baseline.';
      case TrendDirection.stable:
        return 'Your 120-second recovery is broadly stable versus your recent baseline.';
      case TrendDirection.notEnoughData:
        return 'Complete at least 3 assessments to start seeing meaningful recovery trends.';
    }
  }

  String get recoveryGapInsight {
    if (recoveryGapTrend == RecoveryGapTrend.notEnoughData) {
      return 'Complete more assessments to understand whether your recovery happens mostly in the first minute or continues strongly into the second.';
    }

    final latestGap = latestRecoveryGapPercent;
    final recentGap = recentAverageRecoveryGapPercent;

    switch (recoveryGapTrend) {
      case RecoveryGapTrend.widening:
        return 'Your latest test shows a wider gap between 60s and 120s recovery. Early recovery was relatively slower, but recovery continued strongly into the second minute.';
      case RecoveryGapTrend.narrowing:
        return 'Your latest test shows a narrower gap between 60s and 120s recovery. Most of your recovery happened early, with less additional drop in the second minute.';
      case RecoveryGapTrend.stable:
        if (latestGap != null && recentGap != null) {
          return 'Your recovery timing is fairly consistent. The latest second-minute contribution was ${latestGap.toStringAsFixed(1)} percentage points, close to your recent average of ${recentGap.toStringAsFixed(1)}.';
        }
        return 'Your recovery timing is fairly consistent across recent tests.';
      case RecoveryGapTrend.notEnoughData:
        return 'Complete more assessments to understand whether your recovery happens mostly in the first minute or continues strongly into the second.';
    }
  }

  String get coachingFocus {
    if (trendDirection == TrendDirection.notEnoughData) {
      return 'Build a baseline first. Try to complete assessments after similar workouts so the app can learn your normal recovery pattern.';
    }

    if (possibleFatigueMismatch) {
      return 'Your heart rate recovery looks reasonable, but your post-workout feeling is lower than expected. Prioritise sleep, hydration and easier aerobic work before adding intensity.';
    }

    if (possibleHiddenLoadMismatch) {
      return 'You felt okay, but your recovery was slower than expected. Keep the next session controlled and watch for repeated slow recovery.';
    }

    if (recoveryGapTrend == RecoveryGapTrend.widening) {
      return 'Your second-minute recovery is doing more of the work than usual. For the next test, use a consistent cool-down and note whether the session was harder, hotter, or more fatiguing than normal.';
    }

    if (recoveryGapTrend == RecoveryGapTrend.narrowing ||
        stalledPatternCountLast5 >= 3) {
      return 'Your recent tests suggest strong early recovery but less continued drop. Add easy aerobic work and keep recovery measurements consistent for the full two minutes.';
    }

    switch (trendDirection) {
      case TrendDirection.improving:
        return 'Keep the current training rhythm. Avoid increasing both intensity and duration at the same time.';
      case TrendDirection.declining:
        return 'Reduce intensity for your next session and check whether recovery improves after an easier day or rest day.';
      case TrendDirection.stable:
        return 'Maintain consistency. To improve further, add one slightly longer easy aerobic session each week.';
      case TrendDirection.notEnoughData:
        return 'Build a baseline first.';
    }
  }

  String get whatToTrackNext {
    if (trendDirection == TrendDirection.notEnoughData) {
      return 'Track at least 3 assessments using similar timing after exercise.';
    }

    if (recoveryGapTrend == RecoveryGapTrend.widening) {
      return 'Watch whether the 60s-to-120s gap stays wide after hard sessions, hot conditions, poor sleep, or high-effort workouts.';
    }

    if (recoveryGapTrend == RecoveryGapTrend.narrowing) {
      return 'Watch whether your recovery repeatedly drops quickly in the first minute and then plateaus before 120 seconds.';
    }

    if (mostCommonActivityType != null &&
        activityTypeRecoveryAverages.length > 1) {
      return 'Compare whether recovery differs by activity type, especially after $mostCommonActivityType sessions.';
    }

    if (stalledPatternCountLast5 >= 3) {
      return 'Watch whether the plateau repeats after harder workouts or mainly after short, intense sessions.';
    }

    if (subjectiveDeclining) {
      return 'Track whether effort is rising or post-workout feeling is dropping even when recovery numbers look stable.';
    }

    return 'Watch your next 3 assessments and compare 120-second recovery against your recent average.';
  }
}

class TrendService {
  TrendService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<RecoveryTrendSummary> getRecoveryTrendSummary({
    int limit = 20,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final docs = snapshot.docs.map((doc) => doc.data()).toList();

    return buildSummaryFromAssessments(docs);
  }

  RecoveryTrendSummary buildSummaryFromAssessments(
    List<Map<String, dynamic>> assessments,
  ) {
    if (assessments.isEmpty) {
      return const RecoveryTrendSummary(
        assessmentCount: 0,
        trendDirection: TrendDirection.notEnoughData,
      );
    }

    final sorted = [...assessments];

    sorted.sort((a, b) {
      final aTime = _timestampToDate(a['createdAt']) ??
          _timestampToDate(a['workoutDateTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = _timestampToDate(b['createdAt']) ??
          _timestampToDate(b['workoutDateTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final last5 = sorted.take(5).toList();
    final previous5 = sorted.skip(5).take(5).toList();

    final latest = sorted.first;

    final latestRecovery = _recoveryPercent120(latest);
    final latestHrr60 = _numToDouble(latest['hrr60']);
    final latestHrr120 = _numToDouble(latest['hrr120']);
    final latestHrr60Percent = _hrrPercent(latest, 'hrr60');
    final latestHrr120Percent = _hrrPercent(latest, 'hrr120');
    final latestGap = _recoveryGapPercent(latest);

    final recentAverageRecovery =
        _average(last5.map((a) => _recoveryPercent120(a)));
    final previousAverageRecovery =
        _average(previous5.map((a) => _recoveryPercent120(a)));

    final recentAverageGap =
        _average(last5.map((a) => _recoveryGapPercent(a)));
    final previousAverageGap =
        _average(previous5.map((a) => _recoveryGapPercent(a)));

    final gapChangeVsRecent = latestGap != null && recentAverageGap != null
        ? latestGap - recentAverageGap
        : null;

    final changeVsPrevious = recentAverageRecovery != null &&
            previousAverageRecovery != null
        ? recentAverageRecovery - previousAverageRecovery
        : null;

    final trendDirection = _trendDirection(
      assessmentCount: sorted.length,
      recentAverage: recentAverageRecovery,
      previousAverage: previousAverageRecovery,
      latest: latestRecovery,
    );

    final gapTrend = _gapTrend(
      assessmentCount: sorted.length,
      latestGap: latestGap,
      recentAverageGap: recentAverageGap,
      previousAverageGap: previousAverageGap,
    );

    final patternsLast5 =
        last5.map((a) => a['recoveryPattern']?.toString()).whereType<String>();

    final mostCommonPattern = _mostCommon(patternsLast5.toList());

    final stalledCount = patternsLast5
        .where((p) => p.toLowerCase().contains('stall'))
        .length;

    final overallLast5 = last5
        .map((a) => a['overallRecoveryAssessment']?.toString())
        .whereType<String>()
        .toList();

    final excellentCount =
        overallLast5.where((label) => label == 'Excellent').length;

    final goodOrExcellentCount = overallLast5
        .where((label) => label == 'Good' || label == 'Excellent')
        .length;

    final recentEffort =
        _average(last5.map((a) => _numToDouble(a['duringEffortRating'])));
    final previousEffort =
        _average(previous5.map((a) => _numToDouble(a['duringEffortRating'])));

    final recentFeeling =
        _average(last5.map((a) => _numToDouble(a['postWorkoutFeelingRating'])));
    final previousFeeling = _average(
      previous5.map((a) => _numToDouble(a['postWorkoutFeelingRating'])),
    );

    final subjectiveImproving = recentFeeling != null &&
        previousFeeling != null &&
        recentFeeling - previousFeeling >= 1.0;

    final subjectiveDeclining = recentFeeling != null &&
        previousFeeling != null &&
        previousFeeling - recentFeeling >= 1.0;

    final possibleFatigueMismatch = _possibleFatigueMismatch(
      recovery: latestRecovery,
      feelingAfter: _numToDouble(latest['postWorkoutFeelingRating']),
      effort: _numToDouble(latest['duringEffortRating']),
    );

    final possibleHiddenLoadMismatch = _possibleHiddenLoadMismatch(
      recovery: latestRecovery,
      feelingAfter: _numToDouble(latest['postWorkoutFeelingRating']),
    );

    final recoveryValues = sorted
        .map((a) => _recoveryPercent120(a))
        .whereType<double>()
        .toList();

    final activityAverages = _activityAverages(sorted);

    final activityTypes = sorted
        .map((a) => a['activityType']?.toString())
        .whereType<String>()
        .toList();

    return RecoveryTrendSummary(
      assessmentCount: sorted.length,
      trendDirection: trendDirection,
      latestRecoveryPercent120: latestRecovery,
      recentAverageRecoveryPercent120: recentAverageRecovery,
      previousAverageRecoveryPercent120: previousAverageRecovery,
      changeVsPreviousAverage: changeVsPrevious,
      latestHrr60: latestHrr60,
      latestHrr120: latestHrr120,
      latestHrr60Percent: latestHrr60Percent,
      latestHrr120Percent: latestHrr120Percent,
      recentAverageHrr60:
          _average(last5.map((a) => _numToDouble(a['hrr60']))),
      recentAverageHrr120:
          _average(last5.map((a) => _numToDouble(a['hrr120']))),
      recentAverageHrr60Percent:
          _average(last5.map((a) => _hrrPercent(a, 'hrr60'))),
      recentAverageHrr120Percent:
          _average(last5.map((a) => _hrrPercent(a, 'hrr120'))),
      latestRecoveryGapPercent: latestGap,
      recentAverageRecoveryGapPercent: recentAverageGap,
      previousAverageRecoveryGapPercent: previousAverageGap,
      recoveryGapChangeVsRecentAverage: gapChangeVsRecent,
      recoveryGapTrend: gapTrend,
      recentAveragePeakHr:
          _average(last5.map((a) => _numToDouble(a['peakHr']))),
      recentAverageHr60:
          _average(last5.map((a) => _numToDouble(a['hr60']))),
      recentAverageHr120:
          _average(last5.map((a) => _numToDouble(a['hr120']))),
      recentAverageEffort: recentEffort,
      recentAverageFeelingAfter: recentFeeling,
      mostCommonPatternLast5: mostCommonPattern,
      stalledPatternCountLast5: stalledCount,
      excellentCountLast5: excellentCount,
      goodOrExcellentCountLast5: goodOrExcellentCount,
      possibleFatigueMismatch: possibleFatigueMismatch,
      possibleHiddenLoadMismatch: possibleHiddenLoadMismatch,
      subjectiveImproving: subjectiveImproving,
      subjectiveDeclining: subjectiveDeclining,
      recoveryVariability: _standardDeviation(recoveryValues),
      bestRecoveryPercent120: recoveryValues.isEmpty
          ? null
          : recoveryValues.reduce((a, b) => a > b ? a : b),
      worstRecoveryPercent120: recoveryValues.isEmpty
          ? null
          : recoveryValues.reduce((a, b) => a < b ? a : b),
      latestActivityType: latest['activityType']?.toString(),
      mostCommonActivityType: _mostCommon(activityTypes),
      activityTypeRecoveryAverages: activityAverages,
    );
  }

  TrendDirection _trendDirection({
    required int assessmentCount,
    required double? recentAverage,
    required double? previousAverage,
    required double? latest,
  }) {
    if (assessmentCount < 3) {
      return TrendDirection.notEnoughData;
    }

    if (previousAverage == null || recentAverage == null) {
      return TrendDirection.stable;
    }

    final change = recentAverage - previousAverage;

    if (change >= 5.0) return TrendDirection.improving;
    if (change <= -5.0) return TrendDirection.declining;

    return TrendDirection.stable;
  }

  RecoveryGapTrend _gapTrend({
    required int assessmentCount,
    required double? latestGap,
    required double? recentAverageGap,
    required double? previousAverageGap,
  }) {
    if (assessmentCount < 3 || latestGap == null || recentAverageGap == null) {
      return RecoveryGapTrend.notEnoughData;
    }

    final latestVsRecent = latestGap - recentAverageGap;

    /// Threshold is in percentage points of peak HR.
    /// A 5-point change is usually visible and meaningful enough to mention.
    if (latestVsRecent >= 5.0) return RecoveryGapTrend.widening;
    if (latestVsRecent <= -5.0) return RecoveryGapTrend.narrowing;

    if (previousAverageGap != null) {
      final recentVsPrevious = recentAverageGap - previousAverageGap;
      if (recentVsPrevious >= 5.0) return RecoveryGapTrend.widening;
      if (recentVsPrevious <= -5.0) return RecoveryGapTrend.narrowing;
    }

    return RecoveryGapTrend.stable;
  }

  bool _possibleFatigueMismatch({
    required double? recovery,
    required double? feelingAfter,
    required double? effort,
  }) {
    if (recovery == null || feelingAfter == null) return false;

    final goodRecovery = recovery >= 25;
    final poorFeeling = feelingAfter <= 4;
    final hardEffort = effort != null && effort >= 7;

    return goodRecovery && poorFeeling && hardEffort;
  }

  bool _possibleHiddenLoadMismatch({
    required double? recovery,
    required double? feelingAfter,
  }) {
    if (recovery == null || feelingAfter == null) return false;

    final slowRecovery = recovery < 20;
    final goodFeeling = feelingAfter >= 7;

    return slowRecovery && goodFeeling;
  }

  Map<String, double> _activityAverages(List<Map<String, dynamic>> assessments) {
    final grouped = <String, List<double>>{};

    for (final assessment in assessments) {
      final activity = assessment['activityType']?.toString();
      final recovery = _recoveryPercent120(assessment);

      if (activity == null || recovery == null) continue;

      grouped.putIfAbsent(activity, () => []).add(recovery);
    }

    return grouped.map(
      (activity, values) => MapEntry(
        activity,
        values.reduce((a, b) => a + b) / values.length,
      ),
    );
  }

  double? _recoveryPercent120(Map<String, dynamic> assessment) {
    final stored = _numToDouble(assessment['recoveryPercent120']);
    if (stored != null) return stored;

    return _hrrPercent(assessment, 'hrr120');
  }

  double? _hrrPercent(Map<String, dynamic> assessment, String hrrField) {
    final peakHr = _numToDouble(assessment['peakHr']);
    final hrr = _numToDouble(assessment[hrrField]);

    if (peakHr == null || peakHr <= 0 || hrr == null) return null;

    return (hrr / peakHr) * 100.0;
  }

  double? _recoveryGapPercent(Map<String, dynamic> assessment) {
    final hrr60Percent = _hrrPercent(assessment, 'hrr60');
    final hrr120Percent = _hrrPercent(assessment, 'hrr120');

    if (hrr60Percent == null || hrr120Percent == null) return null;

    return hrr120Percent - hrr60Percent;
  }

  double? _average(Iterable<double?> values) {
    final valid = values.whereType<double>().toList();

    if (valid.isEmpty) return null;

    return valid.reduce((a, b) => a + b) / valid.length;
  }

  double? _standardDeviation(List<double> values) {
    if (values.length < 2) return null;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((value) {
              final diff = value - mean;
              return diff * diff;
            })
            .reduce((a, b) => a + b) /
        values.length;

    return variance.sqrt();
  }

  String? _mostCommon(List<String> values) {
    if (values.isEmpty) return null;

    final counts = <String, int>{};

    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.first.key;
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  double? _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}

extension on double {
  double sqrt() {
    var x = this;
    var last = 0.0;

    if (x <= 0) return 0;

    while ((x - last).abs() > 0.000001) {
      last = x;
      x = (x + this / x) / 2;
    }

    return x;
  }
}