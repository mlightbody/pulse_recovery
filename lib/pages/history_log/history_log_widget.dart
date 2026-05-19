import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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

  double _averageRecovery(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final values = docs
        .map((doc) => doc.data()['recoveryPercent120'])
        .whereType<num>()
        .map((v) => v.toDouble())
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double _bestRecovery(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final values = docs
        .map((doc) => doc.data()['recoveryPercent120'])
        .whereType<num>()
        .map((v) => v.toDouble())
        .toList();

    if (values.isEmpty) return 0;

    values.sort();
    return values.last;
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
    final patternDescription =
        data['recoveryPatternDescription']?.toString();
    final patternAdvice = data['recoveryPatternAdvice']?.toString();

    final createdAt = data['createdAt'];
    final peakHr = data['peakHr'];
    final hr60 = data['hr60'];
    final hr120 = data['hr120'];
    final hrr60 = data['hrr60'];
    final hrr120 = data['hrr120'];
    final rpe = data['duringEffortRating'];
    final feelingAfter = data['postWorkoutFeelingRating'];

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            'Effort during: ${rpe ?? '-'} / 10   •   Felt after: ${feelingAfter ?? '-'} / 10',
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
                            value:
                                '${_bestRecovery(docs).toStringAsFixed(1)}%',
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