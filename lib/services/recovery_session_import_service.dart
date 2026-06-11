import '../models/heart_rate_sample.dart';
import '../models/pending_recovery_session.dart';
import 'watch_session_service.dart';

class RecoverySessionImportService {
  Future<List<PendingRecoverySession>> getPendingSessions() async {
    await WatchSessionService.instance.refreshLatestSession();

    final watchSession = WatchSessionService.instance.latestSession.value;

    if (watchSession == null) {
      return [];
    }

    return [_fromWatchSession(watchSession)];
  }

  PendingRecoverySession _fromWatchSession(WatchRecoverySession session) {
    final detailedSamples = session.samples.map((sample) {
      return HeartRateSample(
        timestamp: sample.timestamp,
        bpm: sample.hr,
        phase: sample.phase,
      );
    }).toList();

    final recoveryStartedAt = session.recoveryStartTime ?? session.timestamp;

    final fallbackSamples = <HeartRateSample>[
      HeartRateSample(
        timestamp: recoveryStartedAt,
        bpm: session.endHr,
        phase: 'recovery',
      ),
      HeartRateSample(
        timestamp: recoveryStartedAt.add(const Duration(seconds: 60)),
        bpm: session.hr60,
        phase: 'recovery',
      ),
      HeartRateSample(
        timestamp: recoveryStartedAt.add(const Duration(seconds: 120)),
        bpm: session.hr120,
        phase: 'recovery',
      ),
    ];

    return PendingRecoverySession(
      id: session.sessionId.isNotEmpty
          ? session.sessionId
          : 'watch-session-${session.timestamp.millisecondsSinceEpoch}',
      workoutStartedAt: session.workoutStartTime ??
          recoveryStartedAt.subtract(const Duration(minutes: 5)),
      recoveryStartedAt: recoveryStartedAt,
      samples: detailedSamples.isNotEmpty ? detailedSamples : fallbackSamples,
      source: 'Apple Watch',
    );
  }
}