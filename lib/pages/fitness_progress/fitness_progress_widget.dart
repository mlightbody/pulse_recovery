import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/trend_service.dart';
import '/utils/recovery_decision_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fitness_progress_model.dart';
export 'fitness_progress_model.dart';

class FitnessProgressWidget extends StatefulWidget {
  const FitnessProgressWidget({super.key});

  static String routeName = 'FitnessProgress';
  static String routePath = '/fitnessProgress';

  @override
  State<FitnessProgressWidget> createState() => _FitnessProgressWidgetState();
}

class _FitnessProgressWidgetState extends State<FitnessProgressWidget> {
  late FitnessProgressModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const int _maxChartAssessments = 20;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FitnessProgressModel());
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
        .limit(_maxChartAssessments)
        .snapshots();
  }

  void _navigateFromMenu(String value) {
    switch (value) {
      case 'dashboard':
        context.goNamed(DashboardWidget.routeName);
        break;
      case 'new':
        context.goNamed(NewAssessmentWidget.routeName);
        break;
      case 'history':
        context.goNamed(HistoryLogWidget.routeName);
        break;
      case 'settings':
        context.goNamed(ProfileSettingsWidget.routeName);
        break;
    }
  }

  PopupMenuButton<String> _menuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded),
      onSelected: _navigateFromMenu,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
        PopupMenuItem(value: 'new', child: Text('New Assessment')),
        PopupMenuItem(value: 'history', child: Text('History Log')),
        PopupMenuItem(value: 'settings', child: Text('Profile Settings')),
      ],
    );
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  String _formatDateLabel(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final date = timestamp.toDate();
    return '${date.day}/${date.month}';
  }

  List<double> _xData(int count) {
    return List.generate(count, (index) => index.toDouble());
  }

  List<String> _xLabels(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) => _formatDateLabel(doc.data()['createdAt'])).toList();
  }

  AxisLabelInfo _yAxisLabels() {
    return AxisLabelInfo(
      showLabels: true,
      labelTextStyle: FlutterFlowTheme.of(context).bodySmall.override(
            font: GoogleFonts.dmSans(),
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 10,
          ),
      reservedSize: 44,
    );
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

  Widget _emptyChartCard(String message) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.dmSans(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.dmSans(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ],
    );
  }

  Widget _recoveryPercentChart(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.length < 2) {
      return _emptyChartCard(
        'Complete at least 2 assessments to see your recovery trend.',
      );
    }

    final values = docs
        .map((doc) => _asDouble(doc.data()['recoveryPercent120']) ?? 0.0)
        .toList();

    final maxY = values.isEmpty
        ? 50.0
        : (values.reduce((a, b) => a > b ? a : b) + 10).clamp(40.0, 100.0);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: FlutterFlowLineChart(
        data: [
          FFLineChartData(
            xData: _xData(docs.length),
            yData: values,
            settings: LineChartBarData(
              color: FlutterFlowTheme.of(context).primary,
              barWidth: 3,
              isCurved: true,
              belowBarData: BarAreaData(
                show: true,
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
              ),
            ),
          ),
        ],
        chartStylingInfo: const ChartStylingInfo(
          backgroundColor: Colors.transparent,
          showBorder: false,
        ),
        axisBounds: AxisBounds(
          minX: 0,
          maxX: (docs.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
        ),
        xLabels: _xLabels(docs),
        xAxisLabelInfo: AxisLabelInfo(
          showLabels: true,
          labelTextStyle: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.dmSans(),
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 10,
              ),
          reservedSize: 28,
        ),
        yAxisLabelInfo: _yAxisLabels(),
      ),
    );
  }

  Widget _hrrChart(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.length < 2) {
      return _emptyChartCard(
        'Complete at least 2 assessments to compare early and continued recovery.',
      );
    }

    final color60 = Colors.blueAccent;
    final color120 = Colors.green;

    final hrr60PercentValues = docs.map((doc) {
      final data = doc.data();
      final peakHr = _asDouble(data['peakHr']);
      final hrr60 = _asDouble(data['hrr60']);

      if (peakHr == null || peakHr <= 0 || hrr60 == null) return 0.0;

      return (hrr60 / peakHr) * 100;
    }).toList();

    final hrr120PercentValues = docs.map((doc) {
      final data = doc.data();
      final peakHr = _asDouble(data['peakHr']);
      final hrr120 = _asDouble(data['hrr120']);

      if (peakHr == null || peakHr <= 0 || hrr120 == null) return 0.0;

      return (hrr120 / peakHr) * 100;
    }).toList();

    final allValues = [...hrr60PercentValues, ...hrr120PercentValues];

    final maxY = allValues.isEmpty
        ? 50.0
        : (allValues.reduce((a, b) => a > b ? a : b) + 10)
            .clamp(40.0, 100.0);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _legendDot('60s recovery %', color60),
              const SizedBox(width: 16),
              _legendDot('120s recovery %', color120),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FlutterFlowLineChart(
              data: [
                FFLineChartData(
                  xData: _xData(docs.length),
                  yData: hrr60PercentValues,
                  settings: LineChartBarData(
                    color: color60,
                    barWidth: 3,
                    isCurved: true,
                  ),
                ),
                FFLineChartData(
                  xData: _xData(docs.length),
                  yData: hrr120PercentValues,
                  settings: LineChartBarData(
                    color: color120,
                    barWidth: 3,
                    isCurved: true,
                  ),
                ),
              ],
              chartStylingInfo: const ChartStylingInfo(
                backgroundColor: Colors.transparent,
                showBorder: false,
              ),
              axisBounds: AxisBounds(
                minX: 0,
                maxX: (docs.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
              ),
              xLabels: _xLabels(docs),
              xAxisLabelInfo: AxisLabelInfo(
                showLabels: true,
                labelTextStyle:
                    FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.dmSans(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10,
                        ),
                reservedSize: 28,
              ),
              yAxisLabelInfo: _yAxisLabels(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.dmSans(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ],
    );
  }

  Widget _decisionPanel({
    required RecoveryTrendSummary summary,
    required PersonalisedRecoveryAdvice advice,
  }) {
    if (summary.assessmentCount == 0) {
      return _emptyChartCard('Personalised advice is not available yet.');
    }

    final gapChange = summary.recoveryGapChangeVsRecentAverage;

    final gapChangeText = gapChange == null
        ? null
        : '${gapChange >= 0 ? '+' : ''}${gapChange.toStringAsFixed(1)} pts vs recent timing average';

    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(
            advice.patternTitle,
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            advice.whatItMeans,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary.recoveryGapLabel,
                        style:
                            FlutterFlowTheme.of(context).labelLarge.override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                      ),
                    ),
                  ],
                ),
                if (gapChangeText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    gapChangeText,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.dmSans(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  summary.recoveryGapInsight,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        lineHeight: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Possible reasons',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 8),
          ...advice.possibleReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            lineHeight: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Coaching focus',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            advice.coachingFocus,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'What to track next',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            advice.whatToTrackNext,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            advice.confidence,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.dmSans(fontStyle: FontStyle.italic),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  String _summaryValue(
    RecoveryTrendSummary summary,
    String field,
  ) {
    switch (field) {
      case 'count':
        return summary.assessmentCount.toString();
      case 'average':
        final value = summary.recentAverageRecoveryPercent120;
        return value == null ? '—' : '${value.toStringAsFixed(1)}%';
      case 'best':
        final value = summary.bestRecoveryPercent120;
        return value == null ? '—' : '${value.toStringAsFixed(1)}%';
      default:
        return '—';
    }
  }

  RecoveryTrendSummary _buildTrendSummaryFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final assessments = docs.map((doc) => doc.data()).toList();
    return TrendService().buildSummaryFromAssessments(assessments);
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
                    child: Text(
                      'Could not load progress data: ${snapshot.error}',
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // Firestore returns latest 20 newest-first.
              // Reverse only for charts so they display oldest-to-newest.
              final chartDocs = docs.reversed.toList();

              // Build the trend summary and advice from the same streamed docs.
              // This avoids a second Firestore query via getRecoveryTrendSummary().
              final trendSummary = _buildTrendSummaryFromDocs(docs);
              final advice = buildPersonalisedRecoveryAdvice(
                trend: trendSummary,
              );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          child: Column(
                            children: [
                              Text(
                                'Fitness Progress',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                              ),
                              Text(
                                'Recovery trends over time',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.dmSans(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        _menuButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _summaryCard(
                          label: 'Tests',
                          value: _summaryValue(trendSummary, 'count'),
                          icon: Icons.assignment_turned_in_rounded,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          label: 'Avg recovery',
                          value: _summaryValue(trendSummary, 'average'),
                          icon: Icons.favorite_rounded,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          label: 'Best',
                          value: _summaryValue(trendSummary, 'best'),
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle(
                      '120-second recovery %',
                      'Latest 20 assessments. Y-axis shows percentage drop from peak HR.',
                    ),
                    const SizedBox(height: 12),
                    _recoveryPercentChart(chartDocs),
                    const SizedBox(height: 28),
                    _sectionTitle(
                      'Cumulative recovery: 60s vs 120s',
                      'Latest 20 assessments. Shows percentage drop from peak HR by 60 and 120 seconds.',
                    ),
                    const SizedBox(height: 12),
                    _hrrChart(chartDocs),
                    const SizedBox(height: 28),
                    _sectionTitle(
                      'Personalised recovery insight',
                      'Decision-engine feedback based on your recent trend.',
                    ),
                    const SizedBox(height: 12),
                    _decisionPanel(
                      summary: trendSummary,
                      advice: advice,
                    ),
                    const SizedBox(height: 32),
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