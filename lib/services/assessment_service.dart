import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/heart_rate_sample.dart';

class AssessmentService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future saveAssessment({
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

    // Structured advice fields.
    String? decisionState,
    String? reasonTag,
    String? adviceType,
    String? adviceTitle,
    String? adviceSummary,
    String? adviceRecommendation,

    // Optional Apple Watch raw-session fields.
    List<HeartRateSample>? heartRateSamples,
    DateTime? workoutStartedAt,
    DateTime? recoveryStartedAt,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final assessmentsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessments');

    // Get the immediately previous assessment before saving the new one.
    final previousSnapshot = await assessmentsRef
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    final previousDoc =
        previousSnapshot.docs.isEmpty ? null : previousSnapshot.docs.first;

    final previousData = previousDoc?.data();

    final hasRawSamples =
        heartRateSamples != null && heartRateSamples.isNotEmpty;

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
      'source': hasRawSamples ? 'apple_watch' : 'manual',
      'appVersion': '0.1.0',

      // Optional raw Apple Watch session metadata.
      'workoutStartedAt': workoutStartedAt == null
          ? null
          : Timestamp.fromDate(workoutStartedAt),
      'recoveryStartedAt': recoveryStartedAt == null
          ? null
          : Timestamp.fromDate(recoveryStartedAt),
      'heartRateSamples': heartRateSamples
              ?.map(
                (sample) => {
                  'timestamp': Timestamp.fromDate(sample.timestamp),
                  'bpm': sample.bpm,
                  if (sample.phase != null) 'phase': sample.phase,
                },
              )
              .toList() ??
          [],
    };

    if (decisionState != null ||
        reasonTag != null ||
        adviceType != null ||
        adviceTitle != null ||
        adviceSummary != null ||
        adviceRecommendation != null) {
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
  }) {
    if (previousAssessmentId == null || previousData == null) {
      return null;
    }

    final previousAdviceRaw = previousData['advice'];

    if (previousAdviceRaw is! Map) {
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

    final outcomeLabel = _outcomeLabelFromRecoveryChange(
      recoveryPercentChange,
    );

    return {
      'previousAssessmentId': previousAssessmentId,

      // Previous advice metadata.
      'previousAdviceState': previousAdviceRaw['state'],
      'previousAdviceReasonTag': previousAdviceRaw['reasonTag'],
      'previousAdviceType': previousAdviceRaw['type'],
      'previousAdviceTitle': previousAdviceRaw['title'],

      // Outcome values.
      'outcomeLabel': outcomeLabel,
      'recoveryPercentChange': recoveryPercentChange,
      'previousRecoveryPercent120': previousRecovery,
      'currentRecoveryPercent120': currentRecovery,
      'hrr60Change': _nullableIntDifference(
        currentHrr60,
        previousHrr60,
      ),
      'hrr120Change': _nullableIntDifference(
        currentHrr120,
        previousHrr120,
      ),
      'feelingAfterChange': _nullableIntDifference(
        currentFeeling,
        previousFeeling,
      ),
      'rpeChange': _nullableIntDifference(
        currentEffort,
        previousEffort,
      ),

      // Placeholder for later UI question:
      // "Did you follow the previous recommendation?"
      'userSaysFollowedAdvice': null,
      'createdAt': FieldValue.serverTimestamp(),
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