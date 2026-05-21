class HeartRateSample {
  final DateTime timestamp;
  final int bpm;

  const HeartRateSample({
    required this.timestamp,
    required this.bpm,
  });

  double secondsFrom(DateTime startTime) {
    return timestamp.difference(startTime).inMilliseconds / 1000.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bpm': bpm,
    };
  }

  factory HeartRateSample.fromJson(Map<String, dynamic> json) {
    return HeartRateSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      bpm: json['bpm'] as int,
    );
  }
}