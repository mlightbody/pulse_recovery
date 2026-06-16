import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/heart_rate_sample.dart';
import '../utils/recovery_baseline_comparison.dart';
import '../utils/recovery_data_quality.dart';
import '../utils/recovery_session_insight_builder.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _baselineAssessmentCount = 5;

  Future<void> saveAssessment({
    required int peakHr,
    required int hr60,
    required int hr120,
    required int hrr60,
    required int hrr120,
    required double recoveryPercent120,
    required String earlyRecoveryAssessment,
    required String overallRecoveryAssessment,
    required String recoveryPattern,
    int? duringEffortRating,
    int? postWorkoutFeelingRating,
    String? recoveryPatternDescription,
    String? recoveryPatternAdvice,
    String? notes,
    String? source,
    List<HeartRateSample>? heartRateSamples,
    DateTime? workoutStartedAt,
    DateTime? recoveryStartedAt,

    // Structured advice fields.
    //
    // These are saved so that the next assessment can say what happened
    // after the previous recommendation.
    String? decisionState,
    String? reasonTag,
    String? adviceType,
    String? adviceTitle,
    String? adviceSummary,
    String? adviceRecommendation,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final assessmentsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessments');

    // Fetch the latest 5 previous assessments before saving the new one.
    //
    // The first document is still the immediately previous assessment.
    // All documents together form the recent baseline.
    final recentSnapshot = await assessmentsRef
        .orderBy('createdAt', descending: true)
        .limit(_baselineAssessmentCount)
        .get();

    final recentDocs = recentSnapshot.docs;
    final previousDoc = recentDocs.isEmpty ? null : recentDocs.first;
    final previousData = previousDoc?.data();

    final recentAssessmentData =
        recentDocs.map((doc) => doc.data()).toList();

    final recentBaseline = _buildRecentBaseline(recentAssessmentData);

    final dataQuality = RecoveryDataQualityAnalyser.analyse(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
      samples: heartRateSamples ?? const [],
      workoutStartedAt: workoutStartedAt,
      recoveryStartedAt: recoveryStartedAt,
    );

    final baselineComparison = RecoveryBaselineComparator.compare(
      currentRecoveryPercent120: recoveryPercent120,
      recentAssessments: recentAssessmentData,
      baselineWindow: _baselineAssessmentCount,
    );

    final insight = RecoverySessionInsightBuilder.build(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
      rpe: duringEffortRating ?? 5,
      feelingAfter: postWorkoutFeelingRating ?? 5,
      recoveryPatternLabel: recoveryPattern,
      dataQuality: dataQuality,
      baseline: baselineComparison,
    );

    final assessmentData = <String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'workoutDateTime': Timestamp.now(),
      'peakHr': peakHr,
      'hr60': hr60,
      'hr120': hr120,
      'hrr60': hrr60,
      'hrr120': hrr120,
      'recoveryPercent120': recoveryPercent120,
      'earlyRecoveryAssessment': earlyRecoveryAssessment,
      'overallRecoveryAssessment': overallRecoveryAssessment,
      'recoveryPattern': recoveryPattern,
      'recoveryPatternDescription': recoveryPatternDescription,
      'recoveryPatternAdvice': recoveryPatternAdvice,
      'duringEffortRating': duringEffortRating,
      'postWorkoutFeelingRating': postWorkoutFeelingRating,
      'notes': notes,
      'source': source ?? 'manual',
      'appVersion': '0.1.0',
      'decisionEngineVersion': 2,
      'dataQuality': dataQuality.toMap(),
      'baseline': baselineComparison.toMap(),
      'insight': insight.toMap(),
    };

    if (heartRateSamples != null && heartRateSamples.isNotEmpty) {
      assessmentData['heartRateSamples'] =
          heartRateSamples.map((sample) => sample.toJson()).toList();
    }

    if (workoutStartedAt != null) {
      assessmentData['workoutStartedAt'] = Timestamp.fromDate(workoutStartedAt);
    }

    if (recoveryStartedAt != null) {
      assessmentData['recoveryStartedAt'] = Timestamp.fromDate(recoveryStartedAt);
    }

    final hasStructuredAdvice = decisionState != null ||
        reasonTag != null ||
        adviceType != null ||
        adviceTitle != null ||
        adviceSummary != null ||
        adviceRecommendation != null;

    if (hasStructuredAdvice) {
      assessmentData['advice'] = {
        'state': decisionState,
        'reasonTag': reasonTag,
        'type': adviceType,
        'title': adviceTitle,
        'summary': adviceSummary,
        'recommendation': adviceRecommendation,
        'createdAt': FieldValue.serverTimestamp(),
      };
    }

    final previousAdviceOutcome = _buildPreviousAdviceOutcome(
      previousAssessmentId: previousDoc?.id,
      previousData: previousData,
      currentData: assessmentData,
      recentBaseline: recentBaseline,
    );

    if (previousAdviceOutcome != null) {
      assessmentData['previousAdviceOutcome'] = previousAdviceOutcome;
    }

    await assessmentsRef.add(assessmentData);
  }

  Map<String, dynamic>? _buildPreviousAdviceOutcome({
    required String? previousAssessmentId,
    required Map<String, dynamic>? previousData,
    required Map<String, dynamic> currentData,
    required Map<String, dynamic>? recentBaseline,
  }) {
    if (previousAssessmentId == null || previousData == null) {
      return null;
    }

    final previousAdvice = _extractPreviousAdvice(previousData);

    if (previousAdvice == null) {
      return null;
    }

    final previousRecovery = _toDouble(previousData['recoveryPercent120']);
    final currentRecovery = _toDouble(currentData['recoveryPercent120']);

    if (previousRecovery == null || currentRecovery == null) {
      return null;
    }

    final previousHrr60 = _toInt(previousData['hrr60']);
    final currentHrr60 = _toInt(currentData['hrr60']);

    final previousHrr120 = _toInt(previousData['hrr120']);
    final currentHrr120 = _toInt(currentData['hrr120']);

    final previousFeeling = _toInt(previousData['postWorkoutFeelingRating']);
    final currentFeeling = _toInt(currentData['postWorkoutFeelingRating']);

    final previousEffort = _toInt(previousData['duringEffortRating']);
    final currentEffort = _toInt(currentData['duringEffortRating']);

    final recoveryPercentChange = currentRecovery - previousRecovery;

    final outcome = <String, dynamic>{
      'previousAssessmentId': previousAssessmentId,

      // Previous advice metadata.
      'previousAdviceState': previousAdvice['state'],
      'previousAdviceReasonTag': previousAdvice['reasonTag'],
      'previousAdviceType': previousAdvice['type'],
      'previousAdviceTitle': previousAdvice['title'],
      'previousAdviceSummary': previousAdvice['summary'],
      'previousAdviceRecommendation': previousAdvice['recommendation'],

      // Existing previous-to-current comparison fields.
      //
      // These are kept for backwards compatibility and for simple continuity.
      'outcomeLabel': _outcomeLabelFromRecoveryChange(recoveryPercentChange),
      'recoveryPercentChange': recoveryPercentChange,
      'previousRecoveryPercent120': previousRecovery,
      'currentRecoveryPercent120': currentRecovery,
      'hrr60Change': _nullableIntDifference(currentHrr60, previousHrr60),
      'hrr120Change': _nullableIntDifference(currentHrr120, previousHrr120),
      'feelingAfterChange': _nullableIntDifference(currentFeeling, previousFeeling),
      'rpeChange': _nullableIntDifference(currentEffort, previousEffort),

      // Placeholder for later UI question:
      // "Did you follow the previous recommendation?"
      'userSaysFollowedAdvice': null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (recentBaseline != null) {
      final baselineRecovery =
          _toDouble(recentBaseline['baselineRecoveryPercent120']);
      final baselineHrr60 = _toDouble(recentBaseline['baselineHrr60']);
      final baselineHrr120 = _toDouble(recentBaseline['baselineHrr120']);
      final baselineFeeling =
          _toDouble(recentBaseline['baselinePostWorkoutFeelingRating']);
      final baselineEffort =
          _toDouble(recentBaseline['baselineDuringEffortRating']);

      final currentRecoveryVsBaseline =
          baselineRecovery == null ? null : currentRecovery - baselineRecovery;

      final currentHrr60VsBaseline =
          baselineHrr60 == null || currentHrr60 == null
              ? null
              : currentHrr60 - baselineHrr60;

      final currentHrr120VsBaseline =
          baselineHrr120 == null || currentHrr120 == null
              ? null
              : currentHrr120 - baselineHrr120;

      final currentFeelingVsBaseline =
          baselineFeeling == null || currentFeeling == null
              ? null
              : currentFeeling - baselineFeeling;

      final currentEffortVsBaseline =
          baselineEffort == null || currentEffort == null
              ? null
              : currentEffort - baselineEffort;

      outcome.addAll({
        // Baseline metadata.
        'baselineWindow': _baselineAssessmentCount,
        'baselineAssessmentCount': recentBaseline['baselineAssessmentCount'],

        // Baseline values.
        'baselineRecoveryPercent120': baselineRecovery,
        'baselineHrr60': baselineHrr60,
        'baselineHrr120': baselineHrr120,
        'baselinePostWorkoutFeelingRating': baselineFeeling,
        'baselineDuringEffortRating': baselineEffort,

        // Current result compared with recent baseline.
        'currentVsBaselineRecoveryPercentChange': currentRecoveryVsBaseline,
        'currentVsBaselineHrr60Change': currentHrr60VsBaseline,
        'currentVsBaselineHrr120Change': currentHrr120VsBaseline,
        'currentVsBaselineFeelingAfterChange': currentFeelingVsBaseline,
        'currentVsBaselineRpeChange': currentEffortVsBaseline,

        // Safer interpretation label.
        //
        // This avoids implying that the previous advice caused the result.
        'baselineComparisonLabel': _baselineComparisonLabel(
          currentRecoveryVsBaseline,
        ),
      });
    }

    return outcome;
  }

  Map<String, dynamic>? _buildRecentBaseline(
    List<Map<String, dynamic>> previousAssessments,
  ) {
    if (previousAssessments.isEmpty) {
      return null;
    }

    final recoveryValues = <double>[];
    final hrr60Values = <double>[];
    final hrr120Values = <double>[];
    final feelingValues = <double>[];
    final effortValues = <double>[];

    for (final data in previousAssessments) {
      final recovery = _toDouble(data['recoveryPercent120']);
      final hrr60 = _toDouble(data['hrr60']);
      final hrr120 = _toDouble(data['hrr120']);
      final feeling = _toDouble(data['postWorkoutFeelingRating']);
      final effort = _toDouble(data['duringEffortRating']);

      if (recovery != null) recoveryValues.add(recovery);
      if (hrr60 != null) hrr60Values.add(hrr60);
      if (hrr120 != null) hrr120Values.add(hrr120);
      if (feeling != null) feelingValues.add(feeling);
      if (effort != null) effortValues.add(effort);
    }

    if (recoveryValues.isEmpty) {
      return null;
    }

    return {
      'baselineAssessmentCount': previousAssessments.length,
      'baselineRecoveryPercent120': _averageOrNull(recoveryValues),
      'baselineHrr60': _averageOrNull(hrr60Values),
      'baselineHrr120': _averageOrNull(hrr120Values),
      'baselinePostWorkoutFeelingRating': _averageOrNull(feelingValues),
      'baselineDuringEffortRating': _averageOrNull(effortValues),
    };
  }

  Map<String, dynamic>? _extractPreviousAdvice(
    Map<String, dynamic> previousData,
  ) {
    final previousAdviceRaw = previousData['advice'];

    if (previousAdviceRaw is Map) {
      return {
        'state': previousAdviceRaw['state'],
        'reasonTag': previousAdviceRaw['reasonTag'],
        'type': previousAdviceRaw['type'],
        'title': previousAdviceRaw['title'],
        'summary': previousAdviceRaw['summary'],
        'recommendation': previousAdviceRaw['recommendation'],
      };
    }

    // Fallback for older assessments saved before the structured advice map.
    final fallbackTitle = previousData['recoveryPattern'];
    final fallbackSummary = previousData['recoveryPatternDescription'];
    final fallbackRecommendation = previousData['recoveryPatternAdvice'];

    if (fallbackTitle == null &&
        fallbackSummary == null &&
        fallbackRecommendation == null) {
      return null;
    }

    return {
      'state': null,
      'reasonTag': 'legacy_recovery_pattern',
      'type': 'legacy_current_session',
      'title': fallbackTitle,
      'summary': fallbackSummary,
      'recommendation': fallbackRecommendation,
    };
  }

  String _outcomeLabelFromRecoveryChange(double change) {
    if (change >= 5.0) {
      return 'improved';
    }

    if (change <= -5.0) {
      return 'worse';
    }

    return 'stable';
  }

  String? _baselineComparisonLabel(double? change) {
    if (change == null) {
      return null;
    }

    if (change >= 5.0) {
      return 'above_recent_baseline';
    }

    if (change <= -5.0) {
      return 'below_recent_baseline';
    }

    return 'near_recent_baseline';
  }

  double? _averageOrNull(List<double> values) {
    if (values.isEmpty) {
      return null;
    }

    final total = values.fold(0.0, (sum, value) => sum + value);

    return total / values.length;
  }

  int? _nullableIntDifference(int? current, int? previous) {
    if (current == null || previous == null) {
      return null;
    }

    return current - previous;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}