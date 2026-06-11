import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/models/heart_rate_sample.dart';
import '/widgets/recovery_curve_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_log_model.dart';

export 'history_log_model.dart';

class HistoryLogWidget extends StatefulWidget {
  const HistoryLogWidget({super.key});

  static String routeName = 'HistoryLog';
  static String routePath = '/historyLog';

  @override
  State<HistoryLogWidget> createState() => _HistoryLogWidgetState();
}

class _HistoryLogWidgetState extends State<HistoryLogWidget> {
  late HistoryLogModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryLogModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _assessmentStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assessments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'Unknown date';

    final date = timestamp.toDate();

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPercent(dynamic value) {
    if (value is num) {
      return '${value.toStringAsFixed(1)}%';
    }

    return '-';
  }

  Color _badgeColor(BuildContext context, String? label) {
    switch (label) {
      case 'Excellent':
        return FlutterFlowTheme.of(context).success;
      case 'Good':
        return FlutterFlowTheme.of(context).primary;
      case 'Average':
      case 'Fair':
        return FlutterFlowTheme.of(context).secondary;
      case 'Poor':
      case 'Low':
        return FlutterFlowTheme.of(context).error;
      default:
        return FlutterFlowTheme.of(context).secondaryText;
    }
  }

  double _averageRecovery(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final values = docs
        .map((doc) => doc.data()['recoveryPercent120'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double _bestRecovery(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final values = docs
        .map((doc) => doc.data()['recoveryPercent120'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();

    if (values.isEmpty) return 0;

    values.sort();
    return values.last;
  }

  DateTime? _dateTimeFromFirestoreValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  List<HeartRateSample> _heartRateSamplesFromAssessment(
    Map<String, dynamic> data,
  ) {
    final rawSamples = data['heartRateSamples'];

    if (rawSamples is! List) {
      return [];
    }

    final samples = <HeartRateSample>[];

    for (final rawSample in rawSamples) {
      if (rawSample is! Map) continue;

      final timestamp = _dateTimeFromFirestoreValue(rawSample['timestamp']);
      final bpmRaw = rawSample['bpm'];
      final phaseRaw = rawSample['phase'];

      if (timestamp == null || bpmRaw is! num) {
        continue;
      }

      samples.add(
        HeartRateSample(
          timestamp: timestamp,
          bpm: bpmRaw.round(),
          phase: phaseRaw?.toString(),
        ),
      );
    }

    samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return samples;
  }

  List<HeartRateSample> _dedupeSamples(List<HeartRateSample> samples) {
    final seen = <String>{};
    final deduped = <HeartRateSample>[];

    for (final sample in samples) {
      final key =
          '${sample.timestamp.millisecondsSinceEpoch}_${sample.bpm}_${sample.phase ?? ''}';

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      deduped.add(sample);
    }

    return deduped;
  }

  List<HeartRateSample> _recoveryCurveSamplesFromAssessment(
    Map<String, dynamic> data,
  ) {
    final allSamples = _heartRateSamplesFromAssessment(data);

    if (allSamples.isEmpty) {
      return [];
    }

    final recoveryStartedAt =
        _dateTimeFromFirestoreValue(data['recoveryStartedAt']);

    final explicitRecoverySamples = allSamples.where((sample) {
      return sample.phase?.toLowerCase() == 'recovery';
    }).toList();

    List<HeartRateSample> curveSamples;

    if (explicitRecoverySamples.isNotEmpty) {
      curveSamples = explicitRecoverySamples;
    } else if (recoveryStartedAt != null) {
      // Fallback for older records that may not have saved the phase field.
      curveSamples = allSamples.where((sample) {
        final secondsFromRecoveryStart =
            sample.timestamp.difference(recoveryStartedAt).inMilliseconds /
                1000.0;

        return secondsFromRecoveryStart >= 0 &&
            secondsFromRecoveryStart <= 125;
      }).toList();
    } else {
      // Final fallback for legacy records. This preserves existing behaviour
      // rather than hiding charts for older assessments.
      curveSamples = allSamples;
    }

    curveSamples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final endHrRaw = data['endHr'] ?? data['peakHr'];
    final shouldAddSyntheticStart =
        recoveryStartedAt != null && endHrRaw is num;

    if (shouldAddSyntheticStart) {
      // Remove any real sample that would also plot at or very near t = 0.
      // This avoids two points at the chart origin if Apple Watch happened
      // to provide a recovery sample exactly when recovery started.
      curveSamples = curveSamples.where((sample) {
        final millisecondsFromStart =
            sample.timestamp.difference(recoveryStartedAt).inMilliseconds.abs();

        return millisecondsFromStart > 1000;
      }).toList();

      curveSamples.insert(
        0,
        HeartRateSample(
          timestamp: recoveryStartedAt,
          bpm: endHrRaw.round(),
          phase: 'recovery',
        ),
      );
    }

    curveSamples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return _dedupeSamples(curveSamples);
  }

  DateTime? _recoveryChartStartTime(
    Map<String, dynamic> data,
    List<HeartRateSample> curveSamples,
  ) {
    if (curveSamples.isEmpty) {
      return null;
    }

    final storedRecoveryStartedAt =
        _dateTimeFromFirestoreValue(data['recoveryStartedAt']);

    if (storedRecoveryStartedAt != null) {
      return storedRecoveryStartedAt;
    }

    return curveSamples.first.timestamp;
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: FlutterFlowTheme.of(context).primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coachingTipCard(String advice) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: FlutterFlowTheme.of(context).primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advice,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assessmentCard(Map<String, dynamic> data) {
    final overall = data['overallRecoveryAssessment']?.toString();
    final pattern = data['recoveryPattern']?.toString();
    final patternDescription = data['recoveryPatternDescription']?.toString();
    final patternAdvice = data['recoveryPatternAdvice']?.toString();

    final createdAt = data['createdAt'];
    final peakHr = data['peakHr'];
    final hr60 = data['hr60'];
    final hr120 = data['hr120'];
    final hrr60 = data['hrr60'];
    final hrr120 = data['hrr120'];
    final rpe = data['duringEffortRating'];
    final feelingAfter = data['postWorkoutFeelingRating'];

    final recoveryCurveSamples = _recoveryCurveSamplesFromAssessment(data);
    final recoveryChartStartTime =
        _recoveryChartStartTime(data, recoveryCurveSamples);

    final shouldShowRecoveryCurve =
        recoveryChartStartTime != null && recoveryCurveSamples.length >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatTimestamp(createdAt),
                  style: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _badgeColor(context, overall).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  overall ?? 'Assessment',
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                        color: _badgeColor(context, overall),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatPercent(data['recoveryPercent120']),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          Text(
            '120-second recovery',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('Peak: $peakHr bpm'),
              Text('60s: $hr60 bpm'),
              Text('120s: $hr120 bpm'),
              Text('Drop 60s: $hrr60'),
              Text('Drop 120s: $hrr120'),
            ],
          ),
          if (shouldShowRecoveryCurve) ...[
            const SizedBox(height: 16),
            Text(
              'Recovery curve',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            RecoveryCurveChart(
              samples: recoveryCurveSamples,
              recoveryStartedAt: recoveryChartStartTime,
              height: 150,
            ),
          ],
          if (pattern != null && pattern.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              pattern,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
            ),
          ],
          if (patternDescription != null && patternDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              patternDescription,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
          if (patternAdvice != null && patternAdvice.isNotEmpty)
            _coachingTipCard(patternAdvice),
          const SizedBox(height: 12),
          Text(
            'Effort during: ${rpe ?? '-'} / 10 • Felt after: ${feelingAfter ?? '-'} / 10',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _assessmentStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load history: ${snapshot.error}'),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            context.goNamed(DashboardWidget.routeName);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'History Log',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your saved recovery assessments.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (docs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history_rounded, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'No assessments yet',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete your first assessment to start building your recovery history.',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                context.goNamed(
                                  NewAssessmentWidget.routeName,
                                );
                              },
                              child: const Text('Start Assessment'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          _summaryCard(
                            label: 'Assessments',
                            value: docs.length.toString(),
                            icon: Icons.assignment_turned_in_rounded,
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            label: 'Avg recovery',
                            value:
                                '${_averageRecovery(docs).toStringAsFixed(1)}%',
                            icon: Icons.favorite_rounded,
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            label: 'Best',
                            value: '${_bestRecovery(docs).toStringAsFixed(1)}%',
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...docs.map((doc) => _assessmentCard(doc.data())),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}