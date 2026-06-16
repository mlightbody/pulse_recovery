class HeartRateSample {
  final DateTime timestamp;
  final int bpm;

  /// Optional phase label, usually:
  /// - "workout"
  /// - "recovery"
  ///
  /// Kept optional so older/manual data still works.
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

  factory HeartRateSample.fromJson(Map<String, dynamic> json) {
    return HeartRateSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      bpm: _asInt(json['bpm']),
      phase: json['phase']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}