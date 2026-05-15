import '/components/band_indicator/band_indicator_widget.dart';
import '/components/button/button_widget.dart';
import '/components/pie_chart/pie_chart_widget.dart';
import '/components/result_stat/result_stat_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/recovery_pattern.dart';
import '/utils/recovery_decision_engine.dart';
import 'dart:ui';
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
      case 'home':
        context.goNamed(OnboardingWidget.routeName);
        break;
      case 'dashboard':
        context.goNamed(DashboardWidget.routeName);
        break;
      case 'new':
        context.goNamed(NewAssessmentWidget.routeName);
        break;
      case 'result':
        context.goNamed(AssessmentResultWidget.routeName);
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

  bool _isActive(String band, String classification) =>
      band.toLowerCase() == classification.toLowerCase();

  Widget _smallStat({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.25,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peakHr = widget.peakHr ?? 164;
    final hr60 = widget.hr60 ?? 130;
    final hr120 = widget.hr120 ?? 115;
    final recoveryPercent120 = widget.recoveryPercent120 ?? 30.0;
    final earlyRecoveryAssessment = widget.earlyRecoveryAssessment ?? 'Good';
    final overallRecoveryAssessment =
        widget.overallRecoveryAssessment ?? 'Good';

    final rpe = widget.rpe ?? 6;
    final feelingAfter = widget.feelingAfter ?? 7;

    final hrr60 = peakHr - hr60;
    final hrr120 = peakHr - hr120;

    final decision = assessRecoveryDecision(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    final recoveryPattern = calculateRecoveryPattern(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
    );

    final drop1 = recoveryPattern.drop1;
    final drop2 = recoveryPattern.drop2;
    final recoveryPatternRatio = recoveryPattern.ratio;
    final recoveryPatternLabel = recoveryPattern.label;
    final recoveryPatternDescription = recoveryPattern.description;
    final recoveryPatternAdvice = recoveryPattern.shortAdvice;

    final ratioText = recoveryPatternRatio == null
        ? 'not available'
        : recoveryPatternRatio.toStringAsFixed(2);

    final recoveryPercentRounded = recoveryPercent120.round().clamp(0, 100);
    final remainingPercent = 100 - recoveryPercentRounded;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu_rounded),
                onSelected: _navigateFromMenu,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'home', child: Text('Home')),
                  PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
                  PopupMenuItem(value: 'new', child: Text('New Assessment')),
                  PopupMenuItem(
                    value: 'result',
                    child: Text('Assessment Result'),
                  ),
                  PopupMenuItem(
                    value: 'progress',
                    child: Text('Fitness Progress'),
                  ),
                  PopupMenuItem(value: 'history', child: Text('History Log')),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Profile Settings'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () {
                            context.goNamed(NewAssessmentWidget.routeName);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Assessment Result',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FlutterFlowTheme.of(context)
                                .titleLarge
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  letterSpacing: 0.0,
                                  lineHeight: 1.3,
                                ),
                          ),
                        ),
                        FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.share_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),

                    // existing chart and stats remain unchanged...

                    // INSERT THIS CARD AFTER YOUR EXISTING RECOVERY INSIGHT CARD
                    Container(
                      decoration: BoxDecoration(
                        color:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.psychology_alt_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 28.0,
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coaching Recommendation',
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          font: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    decision.title,
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                          ),
                                          color:
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    decision.summary,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.dmSans(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    decision.recommendation,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    'RPE: $rpe/10 • Feeling after: $feelingAfter/10 • Recovery gap: ${decision.recoveryGap.toStringAsFixed(2)}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.dmSans(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32.0),

                    InkWell(
                      onTap: () {
                        context.goNamed(FitnessProgressWidget.routeName);
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: wrapWithModel(
                        model: _model.buttonModel1,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonWidget(
                          content: 'View Progress History',
                          icon: Icon(
                            Icons.show_chart_rounded,
                            color: FlutterFlowTheme.of(context).onSecondary,
                            size: 16.0,
                          ),
                          iconPresent: true,
                          iconEndPresent: false,
                          variant: 'secondary',
                          size: 'medium',
                          fullWidth: false,
                          loading: false,
                          disabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    InkWell(
                      onTap: () {
                        context.goNamed(DashboardWidget.routeName);
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: wrapWithModel(
                        model: _model.buttonModel2,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonWidget(
                          content: 'Done',
                          iconPresent: false,
                          iconEndPresent: false,
                          variant: 'primary',
                          size: 'medium',
                          fullWidth: false,
                          loading: false,
                          disabled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}