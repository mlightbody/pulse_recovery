import '/components/button/button_widget.dart';
import '/components/selection_card/selection_card_widget.dart';
import '/components/step_header/step_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/recovery_pattern.dart';
import '/utils/recovery_decision_engine.dart';
import '/services/assessment_service.dart';
import '/models/pending_recovery_session.dart';
import '/services/recovery_assessment_service.dart';
import '/services/recovery_session_import_service.dart';
import '/services/watch_session_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'new_assessment_model.dart';
export 'new_assessment_model.dart';

class NewAssessmentWidget extends StatefulWidget {
  const NewAssessmentWidget({super.key});

  static String routeName = 'NewAssessment';
  static String routePath = '/newAssessment';

  @override
  State<NewAssessmentWidget> createState() => _NewAssessmentWidgetState();
}

class _NewAssessmentWidgetState extends State<NewAssessmentWidget> {
  late NewAssessmentModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final peakHrController = TextEditingController();
  final hr60Controller = TextEditingController();
  final hr120Controller = TextEditingController();
  final rpeController = TextEditingController();
  final feelingAfterController = TextEditingController();

  final RecoverySessionImportService _importService =
      RecoverySessionImportService();
  final RecoveryAssessmentService _assessmentService =
      RecoveryAssessmentService();

  List<PendingRecoverySession> _pendingSessions = [];
  bool _loadingWatchSessions = true;
  String? _selectedSource;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewAssessmentModel());
    _loadPendingSessions();
  }

  Future<void> _loadPendingSessions() async {
    final sessions = await _importService.getPendingSessions();

    if (!mounted) return;

    setState(() {
      _pendingSessions = sessions;
      _loadingWatchSessions = false;
    });
  }

  @override
  void dispose() {
    peakHrController.dispose();
    hr60Controller.dispose();
    hr120Controller.dispose();
    rpeController.dispose();
    feelingAfterController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _useWatchSession(PendingRecoverySession session) {
    if (!_assessmentService.canCreateAssessmentFromSession(session)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This watch session does not contain enough data.'),
        ),
      );
      return;
    }

    final values = _assessmentService.extractManualAssessmentValues(session);

    setState(() {
      peakHrController.text = values['peakHr'].toString();
      hr60Controller.text = values['hr60'].toString();
      hr120Controller.text = values['hr120'].toString();
      _selectedSource = session.source;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${session.source} values added.\nNow complete effort and feeling.',
        ),
      ),
    );
  }

  String _earlyRecoveryAssessmentFor(int hrr60) {
    if (hrr60 < 12) return 'Low';
    if (hrr60 < 20) return 'Moderate';
    if (hrr60 < 30) return 'Good';
    return 'Excellent';
  }

  String _overallRecoveryAssessmentFor(int hrr120) {
    if (hrr120 < 22) return 'Poor';
    if (hrr120 < 35) return 'Fair';
    if (hrr120 < 45) return 'Average';
    if (hrr120 < 60) return 'Good';
    return 'Excellent';
  }

  Future<void> _generateAssessment() async {
    final peakHr = int.tryParse(peakHrController.text.trim());
    final hr60 = int.tryParse(hr60Controller.text.trim());
    final hr120 = int.tryParse(hr120Controller.text.trim());
    final rpe = int.tryParse(rpeController.text.trim());
    final feelingAfter = int.tryParse(feelingAfterController.text.trim());

    if (peakHr == null ||
        hr60 == null ||
        hr120 == null ||
        rpe == null ||
        feelingAfter == null ||
        peakHr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid heart rate and subjective values.'),
        ),
      );
      return;
    }

    if (rpe < 1 || rpe > 10 || feelingAfter < 1 || feelingAfter > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RPE and feeling after must be between 1 and 10.'),
        ),
      );
      return;
    }

    if (hr60 >= peakHr || hr120 >= peakHr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery heart rates should be lower than peak HR.'),
        ),
      );
      return;
    }

    if (hr120 > hr60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '120-second HR should usually be lower than 60-second HR.',
          ),
        ),
      );
      return;
    }

    final hrr60 = peakHr - hr60;
    final hrr120 = peakHr - hr120;
    final recoveryPercent120 = (hrr120 / peakHr) * 100;

    final earlyRecoveryAssessment = _earlyRecoveryAssessmentFor(hrr60);
    final overallRecoveryAssessment = _overallRecoveryAssessmentFor(hrr120);

    final recoveryPattern = calculateRecoveryPattern(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
    );

    final recoveryDecision = assessRecoveryDecision(
      peakHr: peakHr,
      hr60: hr60,
      hr120: hr120,
      rpe: rpe,
      feelingAfter: feelingAfter,
    );

    try {
      await AssessmentService().saveAssessment(
        peakHr: peakHr,
        hr60: hr60,
        hr120: hr120,
        hrr60: hrr60,
        hrr120: hrr120,
        recoveryPercent120: recoveryPercent120,
        earlyRecoveryAssessment: earlyRecoveryAssessment,
        overallRecoveryAssessment: overallRecoveryAssessment,
        recoveryPattern: recoveryPattern.label,
        recoveryPatternDescription: recoveryPattern.description,
        recoveryPatternAdvice: recoveryPattern.shortAdvice,
        duringEffortRating: rpe,
        postWorkoutFeelingRating: feelingAfter,
        notes: _selectedSource == null ? null : 'Source: $_selectedSource',

        // Structured advice saved so the next assessment can evaluate
        // what happened after this recommendation, including against
        // the recent baseline in AssessmentService.
        decisionState: recoveryDecision.state.name,
        reasonTag: recoveryDecision.reasonTag.name,
        adviceType: 'current_session',
        adviceTitle: recoveryDecision.title,
        adviceSummary: recoveryDecision.summary,
        adviceRecommendation: recoveryDecision.recommendation,
      );

      // If this assessment used imported Apple Watch data, clear the pending
      // watch session only after the Firebase save has succeeded.
      if (_selectedSource != null) {
        await WatchSessionService.instance.clearLatestSession();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save assessment: $e'),
        ),
      );
      return;
    }

    if (!mounted) return;

    if (_selectedSource != null) {
      setState(() {
        _pendingSessions = [];
        _selectedSource = null;
      });
    }

    context.goNamed(
      AssessmentResultWidget.routeName,
      queryParameters: {
        'peakHr': serializeParam(peakHr, ParamType.int),
        'hr60': serializeParam(hr60, ParamType.int),
        'hr120': serializeParam(hr120, ParamType.int),
        'recoveryPercent120':
            serializeParam(recoveryPercent120, ParamType.double),
        'earlyRecoveryAssessment':
            serializeParam(earlyRecoveryAssessment, ParamType.String),
        'overallRecoveryAssessment':
            serializeParam(overallRecoveryAssessment, ParamType.String),
        'rpe': serializeParam(rpe, ParamType.int),
        'feelingAfter': serializeParam(feelingAfter, ParamType.int),
        'drop1': serializeParam(recoveryPattern.drop1, ParamType.int),
        'drop2': serializeParam(recoveryPattern.drop2, ParamType.int),
        'recoveryPatternRatio':
            serializeParam(recoveryPattern.ratio, ParamType.double),
        'recoveryPatternLabel':
            serializeParam(recoveryPattern.label, ParamType.String),
        'recoveryPatternDescription':
            serializeParam(recoveryPattern.description, ParamType.String),
        'recoveryPatternAdvice':
            serializeParam(recoveryPattern.shortAdvice, ParamType.String),
      }.withoutNulls,
    );
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

  InputDecoration _inputDecoration({
    required String hint,
    required String helper,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      suffixIcon: Icon(icon),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _durationChip(String label, {bool selected = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? FlutterFlowTheme.of(context).primaryContainer
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(32.0),
          border: Border.all(
            color: selected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: selected ? FontWeight.bold : null,
                  ),
                  color: selected
                      ? FlutterFlowTheme.of(context).onPrimary
                      : FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  lineHeight: 1.55,
                ),
          ),
        ),
      ),
    );
  }

  Widget _watchSessionSection() {
    if (_loadingWatchSessions) {
      return Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(40.0),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_pendingSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final session = _pendingSessions.first;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(40.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent Watch Session Found',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '${session.source} values can be used to fill the recovery fields below.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.55,
                  ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Peak HR: ${session.peakHr ?? '-'}\n'
              '60-second HR: ${session.hr60 ?? '-'}\n'
              '120-second HR: ${session.hr120 ?? '-'}',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.55,
                  ),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _useWatchSession(session),
              child: ButtonWidget(
                content: _selectedSource == session.source
                    ? 'Watch Values Added'
                    : 'Use Watch Session',
                iconPresent: false,
                iconEndPresent: false,
                variant: 'primary',
                size: 'large',
                fullWidth: true,
                loading: false,
                disabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputSection() {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(40.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedSource != null) ...[
              Text(
                'Using values from $_selectedSource',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primary,
                      letterSpacing: 0.0,
                      lineHeight: 1.55,
                    ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              'Peak Heart Rate',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: peakHrController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g. 165',
                helper: 'BPM at the end of exercise',
                icon: Icons.favorite_rounded,
              ),
            ),
            const SizedBox(height: 24.0),
            Divider(
              height: 16.0,
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            const SizedBox(height: 24.0),
            Text(
              '60-Second Recovery HR',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: hr60Controller,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g. 135',
                helper: 'BPM after 60 seconds of recovery',
                icon: Icons.timer_rounded,
              ),
            ),
            const SizedBox(height: 24.0),
            Divider(
              height: 16.0,
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            const SizedBox(height: 24.0),
            Text(
              '120-Second Recovery HR',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: hr120Controller,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g. 120',
                helper: 'BPM after 120 seconds of recovery',
                icon: Icons.timer_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectiveInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(40.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Workout Effort',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: rpeController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g. 7',
                helper: 'How hard did it feel? 1 = easy, 10 = maximal',
                icon: Icons.speed_rounded,
              ),
            ),
            const SizedBox(height: 24.0),
            Divider(
              height: 16.0,
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Feeling After',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: feelingAfterController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g. 8',
                helper: 'How did you feel after? 1 = poor, 10 = great',
                icon: Icons.mood_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topNavigationMenu() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: PopupMenuButton<String>(
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
        body: SingleChildScrollView(
          primary: false,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topNavigationMenu(),
                const SizedBox(height: 8.0),
                Text(
                  'New Assessment',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        font: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.25,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Enter your heart rate readings and how the workout felt.',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.55,
                      ),
                ),
                const SizedBox(height: 32.0),

                /*
                Activity and Duration are temporarily disabled because they are
                not currently used by the assessment calculation or saved result.

                To restore these sections later, reinsert the original Activity
                and Duration UI blocks here and decide whether their selected
                values should be saved to Firebase and/or passed to the result page.
                */

                wrapWithModel(
                  model: _model.stepHeaderModel3,
                  updateCallback: () => safeSetState(() {}),
                  child: StepHeaderWidget(
                    bg: FlutterFlowTheme.of(context).primaryContainer,
                    number: '1',
                    subtitle: 'Use a watch session or enter your BPM readings',
                    textColor: FlutterFlowTheme.of(context).onPrimaryContainer,
                    title: 'Recovery Data',
                  ),
                ),
                const SizedBox(height: 16.0),
                _watchSessionSection(),
                if (_pendingSessions.isNotEmpty || _loadingWatchSessions)
                  const SizedBox(height: 16.0),
                _inputSection(),
                const SizedBox(height: 32.0),
                StepHeaderWidget(
                  bg: FlutterFlowTheme.of(context).primaryContainer,
                  number: '2',
                  subtitle: 'Add how the workout felt',
                  textColor: FlutterFlowTheme.of(context).onPrimaryContainer,
                  title: 'Subjective Feedback',
                ),
                const SizedBox(height: 16.0),
                _subjectiveInputSection(),
                const SizedBox(height: 32.0),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _generateAssessment,
                  child: wrapWithModel(
                    model: _model.buttonModel,
                    updateCallback: () => safeSetState(() {}),
                    child: ButtonWidget(
                      content: 'Generate Assessment',
                      iconPresent: false,
                      iconEndPresent: false,
                      variant: 'primary',
                      size: 'large',
                      fullWidth: true,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Results are stored in your private history log.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.dmSans(),
                        color: FlutterFlowTheme.of(context).onBackground,
                        letterSpacing: 0.0,
                        lineHeight: 1.5,
                      ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}