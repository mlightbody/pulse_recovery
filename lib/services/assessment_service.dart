import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssessmentService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
    String? notes,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessments')
        .add({
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

      'duringEffortRating': duringEffortRating,
      'postWorkoutFeelingRating': postWorkoutFeelingRating,
      'notes': notes,

      'source': 'manual',
      'appVersion': '0.1.0',
    });
  }
}