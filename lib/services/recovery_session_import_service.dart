import '../models/heart_rate_sample.dart';
import '../models/pending_recovery_session.dart';

class RecoverySessionImportService {
  Future<List<PendingRecoverySession>> getPendingSessions() async {
    // Later this will check Apple Watch / HealthKit / Health Connect.
    // For now it returns a fake watch session so we can build the UI safely.
    return [_fakeWatchSession()];
  }

  PendingRecoverySession _fakeWatchSession() {
    final now = DateTime.now();
    final workoutStarted = now.subtract(const Duration(minutes: 45));
    final recoveryStarted = now.subtract(const Duration(minutes: 8));

    final samples = <HeartRateSample>[
      HeartRateSample(
        timestamp: recoveryStarted.subtract(const Duration(seconds: 30)),
        bpm: 168,
      ),
      HeartRateSample(
        timestamp: recoveryStarted,
        bpm: 165,
      ),
      HeartRateSample(
        timestamp: recoveryStarted.add(const Duration(seconds: 15)),
        bpm: 148,
      ),
      HeartRateSample(
        timestamp: recoveryStarted.add(const Duration(seconds: 30)),
        bpm: 134,
      ),
      HeartRateSample(
        timestamp: recoveryStarted.add(const Duration(seconds: 60)),
        bpm: 112,
      ),
      HeartRateSample(
        timestamp: recoveryStarted.add(const Duration(seconds: 90)),
        bpm: 101,
      ),
      HeartRateSample(
        timestamp: recoveryStarted.add(const Duration(seconds: 120)),
        bpm: 92,
      ),
    ];

    return PendingRecoverySession(
      id: 'fake-watch-session-001',
      workoutStartedAt: workoutStarted,
      recoveryStartedAt: recoveryStarted,
      samples: samples,
      source: 'Apple Watch',
    );
  }
}