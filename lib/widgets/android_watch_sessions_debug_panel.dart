import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/android_watch_session_service.dart';

class AndroidWatchSessionsDebugPanel extends StatefulWidget {
  const AndroidWatchSessionsDebugPanel({super.key});

  @override
  State<AndroidWatchSessionsDebugPanel> createState() =>
      _AndroidWatchSessionsDebugPanelState();
}

class _AndroidWatchSessionsDebugPanelState
    extends State<AndroidWatchSessionsDebugPanel> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!Platform.isAndroid) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions =
          await AndroidWatchSessionService.getReceivedWatchSessions();

      if (!mounted) return;

      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _clearSessions() async {
    await AndroidWatchSessionService.clearReceivedWatchSessions();
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Samsung Watch Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('Received sessions: ${_sessions.length}'),

            const SizedBox(height: 8),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _loadSessions,
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _clearSessions,
                  child: const Text('Clear'),
                ),
              ],
            ),

            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 12),

            if (_sessions.isEmpty && !_loading)
              const Text('No received Samsung watch sessions found.'),

            ..._sessions.map((session) {
              return _WatchSessionCard(session: session);
            }),
          ],
        ),
      ),
    );
  }
}

class _WatchSessionCard extends StatelessWidget {
  const _WatchSessionCard({
    required this.session,
  });

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final sessionId = session['sessionId']?.toString() ?? 'unknown';
    final source = session['source']?.toString() ?? 'unknown';
    final importStatus = session['importStatus']?.toString() ?? 'unknown';

    final peakHr = _asDouble(session['peakHr']);
    final workoutEndHr = _asDouble(session['workoutEndHr']);
    final hr60 = _asDouble(session['hr60']);
    final hr120 = _asDouble(session['hr120']);

    final sampleCount = _asInt(session['sampleCount']);
    final maxHr = _asInt(session['maxHr']);
    final durationSeconds = _asInt(session['durationSeconds']);

    final workoutStartedAtMillis =
        _asInt(session['workoutStartedAtMillis']);
    final workoutEndedAtMillis =
        _asInt(session['workoutEndedAtMillis']);
    final recoveryEndedAtMillis =
        _asInt(session['recoveryEndedAtMillis']);
    final receivedAtMillis =
        _asInt(session['receivedAtMillis']);

    final payload = session['payload']?.toString() ?? '';
    final pointCountFromPayload = _countPointsFromPayload(payload);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Session ID: $sessionId',
            style: const TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 8),

          _InfoRow(
            label: 'Workout start',
            value: _formatMillis(workoutStartedAtMillis),
          ),
          _InfoRow(
            label: 'Workout end',
            value: _formatMillis(workoutEndedAtMillis),
          ),
          _InfoRow(
            label: 'Recovery end',
            value: _formatMillis(recoveryEndedAtMillis),
          ),
          _InfoRow(
            label: 'Received',
            value: _formatMillis(receivedAtMillis),
          ),

          const Divider(),

          _InfoRow(
            label: 'Peak HR',
            value: _formatBpm(peakHr),
          ),
          _InfoRow(
            label: 'Workout end HR',
            value: _formatBpm(workoutEndHr),
          ),
          _InfoRow(
            label: 'HR60',
            value: _formatBpm(hr60),
          ),
          _InfoRow(
            label: 'HR120',
            value: _formatBpm(hr120),
          ),
          _InfoRow(
            label: 'Max recorded HR',
            value: maxHr > 0 ? '$maxHr bpm' : '--',
          ),

          const Divider(),

          _InfoRow(
            label: 'Duration',
            value: _formatDuration(durationSeconds),
          ),
          _InfoRow(
            label: 'Stored sample count',
            value: sampleCount.toString(),
          ),
          _InfoRow(
            label: 'Payload point count',
            value: pointCountFromPayload.toString(),
          ),
          _InfoRow(
            label: 'Import status',
            value: importStatus,
          ),

          const SizedBox(height: 8),

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Raw payload preview'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  payload.length > 1200
                      ? '${payload.substring(0, 1200)}...'
                      : payload,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static String _formatBpm(double? value) {
    if (value == null || value <= 0) {
      return '--';
    }

    return '${value.toInt()} bpm';
  }

  static String _formatMillis(int millis) {
    if (millis <= 0) {
      return '--';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final twoDigitMinute = date.minute.toString().padLeft(2, '0');
    final twoDigitSecond = date.second.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:$twoDigitMinute:$twoDigitSecond';
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '--';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  static int _countPointsFromPayload(String payload) {
    if (payload.trim().isEmpty) {
      return 0;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return 0;
      }

      final points = decoded['points'];

      if (points is List) {
        return points.length;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}