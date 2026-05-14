import '/components/band_indicator/band_indicator_widget.dart';
import '/components/button/button_widget.dart';
import '/components/pie_chart/pie_chart_widget.dart';
import '/components/result_stat/result_stat_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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
  });

  static String routeName = 'AssessmentResult';
  static String routePath = '/assessmentResult';

  final int? peakHr;
  final int? hr60;
  final int? hr120;
  final double? recoveryPercent120;
  final String? earlyRecoveryAssessment;
  final String? overallRecoveryAssessment;

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
    final overallRecoveryAssessment = widget.overallRecoveryAssessment ?? 'Good';

    final hrr60 = peakHr - hr60;
    final hrr120 = peakHr - hr120;
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

                    SizedBox(
                      width: 240.0,
                      height: 240.0,
                      child: Stack(
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        children: [
                          ClipRect(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 20.0,
                                sigmaY: 20.0,
                              ),
                              child: Container(
                                width: 220.0,
                                height: 220.0,
                                decoration: BoxDecoration(
                                  color:
                                      FlutterFlowTheme.of(context).success15,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(80.0),
                                    topRight: Radius.circular(120.0),
                                    bottomLeft: Radius.circular(90.0),
                                    bottomRight: Radius.circular(110.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          wrapWithModel(
                            model: _model.pieChartModel,
                            updateCallback: () => safeSetState(() {}),
                            child: PieChartWidget(
                              data:
                                  '$recoveryPercentRounded,$remainingPercent',
                              labels: 'Recovery,Remaining',
                              colors: '#A8B5A0,divider',
                              centerValue: '$recoveryPercentRounded%',
                              centerValuePresent: true,
                              centerLabel: '120s Reduction',
                              centerLabelPresent: true,
                              animate: false,
                              startAngle: -90.0,
                              variant: 'donut',
                              size: 'large',
                              legend: 'hidden',
                              legendValue: 'percent',
                              ring: 'thick',
                              gap: 'tight',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    Text(
                      'Overall Recovery Classification',
                      style: FlutterFlowTheme.of(context).labelLarge.override(
                            font: GoogleFonts.dmSans(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.3,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(9999.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20.0,
                          8.0,
                          20.0,
                          8.0,
                        ),
                        child: Text(
                          overallRecoveryAssessment,
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: FlutterFlowTheme.of(context).onSurface,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32.0),

                    Text(
                      'Recovery Bands',
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.dmSans(),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: wrapWithModel(
                            model: _model.bandIndicatorModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: BandIndicatorWidget(
                              color: 'secondary',
                              idBar: 'b1',
                              idTxt: 't1',
                              label: 'Poor',
                              isActive: _isActive(
                                  'Poor', overallRecoveryAssessment),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: wrapWithModel(
                            model: _model.bandIndicatorModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: BandIndicatorWidget(
                              color: 'accent',
                              idBar: 'b2',
                              idTxt: 't2',
                              label: 'Fair',
                              isActive:
                                  _isActive('Fair', overallRecoveryAssessment),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: wrapWithModel(
                            model: _model.bandIndicatorModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: BandIndicatorWidget(
                              color: 'background',
                              idBar: 'b3',
                              idTxt: 't3',
                              label: 'Average',
                              isActive: _isActive(
                                  'Average', overallRecoveryAssessment),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: wrapWithModel(
                            model: _model.bandIndicatorModel4,
                            updateCallback: () => safeSetState(() {}),
                            child: BandIndicatorWidget(
                              color: 'success',
                              idBar: 'b4',
                              idTxt: 't4',
                              label: 'Good',
                              isActive:
                                  _isActive('Good', overallRecoveryAssessment),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: wrapWithModel(
                            model: _model.bandIndicatorModel5,
                            updateCallback: () => safeSetState(() {}),
                            child: BandIndicatorWidget(
                              color: '#8FA385',
                              idBar: 'b5',
                              idTxt: 't5',
                              label: 'Excellent',
                              isActive: _isActive(
                                  'Excellent', overallRecoveryAssessment),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32.0),

                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .secondaryBackground,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: wrapWithModel(
                                    model: _model.resultStatModel1,
                                    updateCallback: () => safeSetState(() {}),
                                    child: ResultStatWidget(
                                      idLabel: 'sl1',
                                      idVal: 'sv1',
                                      label: 'Peak HR',
                                      value: '$peakHr bpm',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1.0,
                                  height: 40.0,
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                                Expanded(
                                  child: wrapWithModel(
                                    model: _model.resultStatModel2,
                                    updateCallback: () => safeSetState(() {}),
                                    child: ResultStatWidget(
                                      idLabel: 'sl2',
                                      idVal: 'sv2',
                                      label: '120s HR',
                                      value: '$hr120 bpm',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 32.0,
                              thickness: 1.0,
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _smallStat(
                                    label: '60s Drop',
                                    value: '$hrr60 bpm',
                                    subtitle: earlyRecoveryAssessment,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: _smallStat(
                                    label: '120s Drop',
                                    value: '$hrr120 bpm',
                                    subtitle: overallRecoveryAssessment,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 18.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Manual Assessment • 60s and 120s Recovery',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.dmSans(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.55,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 18.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Completed today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.dmSans(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.55,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32.0),

                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).tertiary,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: FlutterFlowTheme.of(context).onBackground,
                              size: 24.0,
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recovery Insight',
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
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Your heart rate dropped $hrr60 bpm in the first 60 seconds and $hrr120 bpm after 120 seconds. The 60-second drop reflects early autonomic recovery, while the 120-second drop gives a broader view of overall recovery. Early recovery: $earlyRecoveryAssessment. Overall recovery: $overallRecoveryAssessment.',
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