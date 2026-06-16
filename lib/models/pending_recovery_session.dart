import 'heart_rate_sample.dart';

class PendingRecoverySession {
  final String id;
  final DateTime workoutStartedAt;
  final DateTime recoveryStartedAt;
  final List<HeartRateSample> samples;
  final String source;
  final bool analysed;

  const PendingRecoverySession({
    required this.id,
    required this.workoutStartedAt,
    required this.recoveryStartedAt,
    required this.samples,
    required this.source,
    this.analysed = false,
  });

  int? get peakHr {
    if (samples.isEmpty) return null;
    return samples.map((s) => s.bpm).reduce((a, b) => a > b ? a : b);
  }

  int? heartRateNearestToSeconds(int targetSeconds) {
    if (samples.isEmpty) return null;

    final targetTime = recoveryStartedAt.add(Duration(seconds: targetSeconds));

    HeartRateSample nearest = samples.first;
    int smallestDifference = nearest.timestamp
        .difference(targetTime)
        .inMilliseconds
        .abs();

    for (final sample in samples) {
      final diff = sample.timestamp.difference(targetTime).inMilliseconds.abs();

      if (diff < smallestDifference) {
        nearest = sample;
        smallestDifference = diff;
      }
    }

    return nearest.bpm;
  }

  int? get hr60 => heartRateNearestToSeconds(60);

  int? get hr120 => heartRateNearestToSeconds(120);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutStartedAt': workoutStartedAt.toIso8601String(),
      'recoveryStartedAt': recoveryStartedAt.toIso8601String(),
      'samples': samples.map((s) => s.toJson()).toList(),
      'source': source,
      'analysed': analysed,
    };
  }

  factory PendingRecoverySession.fromJson(Map<String, dynamic> json) {
    return PendingRecoverySession(
      id: json['id'] as String,
      workoutStartedAt: DateTime.parse(json['workoutStartedAt'] as String),
      recoveryStartedAt: DateTime.parse(json['recoveryStartedAt'] as String),
      samples: (json['samples'] as List)
          .map((s) => HeartRateSample.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      source: json['source'] as String,
      analysed: json['analysed'] as bool? ?? false,
    );
  }
}