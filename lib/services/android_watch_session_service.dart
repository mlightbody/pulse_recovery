import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class AndroidWatchSessionService {
  static const MethodChannel _channel =
      MethodChannel('pulse_recovery/watch_sessions');

  static Future<List<Map<String, dynamic>>> getReceivedWatchSessions() async {
    if (!Platform.isAndroid) {
      return [];
    }

    final jsonString =
        await _channel.invokeMethod<String>('getReceivedWatchSessions');

    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> clearReceivedWatchSessions() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod('clearReceivedWatchSessions');
  }

  static Future<void> markWatchSessionImported(String sessionId) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod(
      'markWatchSessionImported',
      {'sessionId': sessionId},
    );
  }
}