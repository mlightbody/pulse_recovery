import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WatchHeartRateSample {
  const WatchHeartRateSample({
    required this.timestamp,
    required this.hr,
    required this.phase,
  });

  final DateTime timestamp;
  final int hr;
  final String phase;

  factory WatchHeartRateSample.fromMap(Map<dynamic, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final timestampSeconds = rawTimestamp is num ? rawTimestamp.toDouble() : 0.0;

    return WatchHeartRateSample(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (timestampSeconds * 1000).round(),
      ),
      hr: _asInt(map['hr']),
      phase: map['phase']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch / 1000.0,
      'hr': hr,
      'phase': phase,
    };
  }
}

class WatchRecoverySession {
  const WatchRecoverySession({
    required this.type,
    required this.source,
    required this.sessionId,
    required this.timestamp,
    required this.endHr,
    required this.hr60,
    required this.hr120,
    required this.sampleCount,
    required this.samples,
    this.peakHr,
    this.workoutStartTime,
    this.recoveryStartTime,
  });

  final String type;
  final String source;
  final String sessionId;
  final DateTime timestamp;

  final int endHr;
  final int hr60;
  final int hr120;
  final int? peakHr;

  final int sampleCount;
  final List<WatchHeartRateSample> samples;

  final DateTime? workoutStartTime;
  final DateTime? recoveryStartTime;

  factory WatchRecoverySession.fromMap(Map<dynamic, dynamic> map) {
    final rawSamples = map['samples'];
    final samples = <WatchHeartRateSample>[];

    if (rawSamples is List) {
      for (final item in rawSamples) {
        if (item is Map) {
          samples.add(WatchHeartRateSample.fromMap(item));
        }
      }
    }

    return WatchRecoverySession(
      type: map['type']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      timestamp: _dateFromSeconds(map['timestamp']) ?? DateTime.now(),
      peakHr: _asNullableInt(map['peakHr']),
      endHr: _asInt(map['endHr']),
      hr60: _asInt(map['hr60']),
      hr120: _asInt(map['hr120']),
      workoutStartTime: _dateFromSeconds(map['workoutStartTime']),
      recoveryStartTime: _dateFromSeconds(map['recoveryStartTime']),
      sampleCount: _asInt(map['sampleCount'], fallback: samples.length),
      samples: samples,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'source': source,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch / 1000.0,
      'peakHr': peakHr,
      'endHr': endHr,
      'hr60': hr60,
      'hr120': hr120,
      'workoutStartTime': workoutStartTime == null
          ? null
          : workoutStartTime!.millisecondsSinceEpoch / 1000.0,
      'recoveryStartTime': recoveryStartTime == null
          ? null
          : recoveryStartTime!.millisecondsSinceEpoch / 1000.0,
      'sampleCount': sampleCount,
      'samples': samples.map((sample) => sample.toMap()).toList(),
    };
  }
}

class WatchSessionService {
  WatchSessionService._();

  static final WatchSessionService instance = WatchSessionService._();

  static const MethodChannel _channel = MethodChannel(
    'pulse_recovery/watch_session',
  );

  final ValueNotifier<WatchRecoverySession?> latestSession =
      ValueNotifier<WatchRecoverySession?>(null);

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler(_handleNativeMethodCall);

    await refreshLatestSession();
  }

  Future<void> refreshLatestSession() async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getLatestWatchSession',
      );

      if (result is Map) {
        latestSession.value = WatchRecoverySession.fromMap(result);
      } else {
        latestSession.value = null;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh latest watch session: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> clearLatestSession() async {
    try {
      await _channel.invokeMethod<bool>('clearLatestWatchSession');
      latestSession.value = null;
    } catch (error, stackTrace) {
      debugPrint('Failed to clear latest watch session: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'watchSessionReceived':
        final args = call.arguments;

        if (args is Map) {
          final session = WatchRecoverySession.fromMap(args);
          latestSession.value = session;

          debugPrint(
            'Watch session received: '
            'endHr=${session.endHr}, '
            'hr60=${session.hr60}, '
            'hr120=${session.hr120}, '
            'samples=${session.sampleCount}',
          );
        }
        break;

      case 'watchSessionCleared':
        latestSession.value = null;
        break;

      default:
        debugPrint('Unknown watch session method: ${call.method}');
    }
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  return _asInt(value);
}

DateTime? _dateFromSeconds(dynamic value) {
  if (value is! num) return null;

  return DateTime.fromMillisecondsSinceEpoch(
    (value.toDouble() * 1000).round(),
  );
}