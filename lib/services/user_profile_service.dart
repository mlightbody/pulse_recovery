import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createOrUpdateProfile({
    String? displayName,
    DateTime? dateOfBirth,
    int? restingHr,
    bool consentForResearch = false,
    bool consentForPersonalisation = true,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final uid = user.uid;

    final docRef = _firestore.collection('users').doc(uid);

    final data = {
      'email': user.email,
      'displayName': displayName,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
      'typicalRestingHr': restingHr,

      'consentForResearch': consentForResearch,
      'consentForPersonalisation': consentForPersonalisation,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Create if not exists, update if exists
    await docRef.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('users').doc(user.uid).get();

    return doc.data();
  }
}