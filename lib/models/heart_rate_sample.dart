class HeartRateSample {
  final DateTime timestamp;
  final int bpm;
  final String? phase;

  const HeartRateSample({
    required this.timestamp,
    required this.bpm,
    this.phase,
  });

  double secondsFrom(DateTime startTime) {
    return timestamp.difference(startTime).inMilliseconds / 1000.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bpm': bpm,
      if (phase != null) 'phase': phase,
    };
  }

  factory HeartRateSample.fromJson(Map json) {
    return HeartRateSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      bpm: json['bpm'] as int,
      phase: json['phase'] as String?,
    );
  }
}