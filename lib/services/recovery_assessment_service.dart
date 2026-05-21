import '../models/pending_recovery_session.dart';

class RecoveryAssessmentService {
  bool canCreateAssessmentFromSession(PendingRecoverySession session) {
    return session.peakHr != null &&
        session.hr60 != null &&
        session.hr120 != null;
  }

  Map<String, int?> extractManualAssessmentValues(
    PendingRecoverySession session,
  ) {
    return {
      'peakHr': session.peakHr,
      'hr60': session.hr60,
      'hr120': session.hr120,
    };
  }
}