import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/recovery_decision_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'assessment_result_model.dart';
export 'assessment_result_model.dart';

class AssessmentResultWidget extends StatefulWidget {
  const AssessmentResultWidget({
    super.key,
    this.peakHr,
    this.hr60,
    this.hr120,
    this.recoveryPercent120,
    this.earlyRecoveryAssessment,
    this.overallRecoveryAssessment,
    this.rpe,
    this.feelingAfter,
  });

  static String routeName = 'AssessmentResult';
  static String routePath = '/assessmentResult';

  final int? peakHr;
  final int? hr60;
  final int? hr120;
  final double? recoveryPercent120;
  final String? earlyRecoveryAssessment;
  final String? overallRecoveryAssessment;
  final int? rpe;
  final int? feelingAfter;

  @override
  State<AssessmentResultWidget> createState() => _AssessmentResultWidgetState();
}

class _AssessmentResultWidgetState extends State<AssessmentResultWidget> {
  late AssessmentResultModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AssessmentResultModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _navigateFromMenu(String value) {
    switch (value) {
      case 'dashboard':
        context.goNamed(DashboardWidget.routeName);
        break;
      case 'new':
        context.goNamed(NewAssessmentWidget.routeName);
        break;
      case 'progress':
        context.goNamed(FitnessProgressWidget.routeName);
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
        PopupMenuItem(value: 'progress', child: Text('Fitness Progress')),
        PopupMenuItem(value: 'history', child: Text('History Log')),
        PopupMenuItem(value: 'settings', child: Text('Profile Settings')),
      ],
    );
  }

  Color _bandColor(String band) {
    switch (band.toLowerCase()) {
      case 'excellent':
        return FlutterFlowTheme.of(context).success;
      case 'good':
        return FlutterFlowTheme.of(context).primary;
      case 'average':
      case 'fair':
      case 'moderate':
        return FlutterFlowTheme.of(context).secondary;
      case 'poor':
      case 'low':
        return FlutterFlowTheme.of(context).error;
      default:
        return FlutterFlowTheme.of(context).secondaryText;
    }
  }

  Widget _statCard({
    required String label,
    required String value,
    required String subtitle,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: FlutterFlowTheme.of(context).primary,
              size: 24,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String body,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: FlutterFlowTheme.of(context).primary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FlutterFlowTheme.of(context).labelLarge.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        lineHeight: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachingDetail({
    required String label,
    required String body,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: FlutterFlowTheme.of(context).primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      lineHeight: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coachingCard(
    RecoveryDecisionResult decision,
    int rpe,
    int feelingAfter,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_alt_rounded,
                color: FlutterFlowTheme.of(context).primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coaching recommendation',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _coachingDetail(
            label: 'Training focus',
            body: decision.trainingFocus,
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 16),
          _coachingDetail(
            label: 'Try this',
            body: decision.specificSession,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 16),
          _coachingDetail(
            label: 'Measure this',
            body: decision.measurableTarget,
            icon: Icons.query_stats_rounded,
          ),
          const SizedBox(height: 16),
          _coachingDetail(
            label: 'Response window',
            body: decision.responseWindow,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 16),
          _coachingDetail(
            label: 'Progress rule',
            body: decision.progressRule,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 16),
          _coachingDetail(
            label: 'Hold back if',
            body: decision.holdBackRule,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'Effort: $rpe/10 • Felt after: $feelingAfter/10',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peakHr = widget.peakHr ?? 0;
    final hr60 = widget.hr60 ?? 0;
    final hr120 = widget.hr120 ?? 0;
    final recoveryPercent120 = widget.recoveryPercent120 ?? 0.0;
    final earlyRecoveryAssessment = widget.earlyRecoveryAssessment ?? 'Unknown';
    final overallRecoveryAssessment =
        widget.overallRecoveryAssessment ?? 'Unknown';
    final rpe = widget.rpe ?? 0;
    final feelingAfter = widget.feelingAfter ?? 0;

    final hrr60 = peakHr - hr60;
    final hrr120 = peakHr - hr120;

    final decision = assessRecoveryDecision(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    final overallColor = _bandColor(overallRecoveryAssessment);
    final recoveryPercentText = '${recoveryPercent120.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        context.goNamed(NewAssessmentWidget.routeName);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Assessment Result',
                        textAlign: TextAlign.center,
                        style:
                            FlutterFlowTheme.of(context).headlineMedium.override(
                                  font: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                      ),
                    ),
                    _menuButton(),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: overallColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '120-second recovery',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(),
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recoveryPercentText,
                        style:
                            FlutterFlowTheme.of(context).headlineLarge.override(
                                  font: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                  ),
                                  color: Colors.white,
                                  fontSize: 58,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          overallRecoveryAssessment,
                          style:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        label: '60s drop',
                        value: '$hrr60 bpm',
                        subtitle: earlyRecoveryAssessment,
                        icon: Icons.timer_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: '120s drop',
                        value: '$hrr120 bpm',
                        subtitle: overallRecoveryAssessment,
                        icon: Icons.favorite_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _statCard(
                  label: 'Heart-rate readings',
                  value: '$peakHr → $hr60 → $hr120 bpm',
                  subtitle: 'Peak, 60 seconds, 120 seconds',
                  icon: Icons.monitor_heart_rounded,
                ),
                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Recovery pattern',
                  body:
                      '${decision.recoveryTypeTitle}\n\n${decision.recoveryPatternDetail}',
                  icon: Icons.timeline_rounded,
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'What this test suggests',
                  body: decision.testInterpretation,
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 16),
                _coachingCard(decision, rpe, feelingAfter),
                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Trend context',
                  body:
                      'This page explains the assessment you just completed. For personalised trend advice based on your wider history, use Fitness Progress.',
                  icon: Icons.show_chart_rounded,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(FitnessProgressWidget.routeName);
                  },
                  icon: const Icon(Icons.show_chart_rounded),
                  label: const Text('View Fitness Progress'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(NewAssessmentWidget.routeName);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Assessment'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.goNamed(DashboardWidget.routeName);
                  },
                  child: const Text('Done'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}