import '/components/button/button_widget.dart';
import '/components/selection_card/selection_card_widget.dart';
import '/components/step_header/step_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/recovery_pattern.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewAssessmentModel());
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

  void _generateAssessment() {
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
                wrapWithModel(
                  model: _model.stepHeaderModel1,
                  updateCallback: () => safeSetState(() {}),
                  child: StepHeaderWidget(
                    bg: FlutterFlowTheme.of(context).primary,
                    number: '1',
                    subtitle: 'Select your exercise type',
                    textColor: FlutterFlowTheme.of(context).onPrimary,
                    title: 'Activity',
                  ),
                ),
                const SizedBox(height: 16.0),
                wrapWithModel(
                  model: _model.selectionCardModel1,
                  updateCallback: () => safeSetState(() {}),
                  child: SelectionCardWidget(
                    desc: 'Outdoor or treadmill steady pace',
                    icon: Icon(
                      Icons.directions_run_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 24.0,
                    ),
                    label: 'Running',
                    selected: true,
                  ),
                ),
                const SizedBox(height: 12.0),
                wrapWithModel(
                  model: _model.selectionCardModel2,
                  updateCallback: () => safeSetState(() {}),
                  child: SelectionCardWidget(
                    desc: 'Road bike or stationary cycling',
                    icon: Icon(
                      Icons.directions_bike_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    label: 'Cycling',
                    selected: false,
                  ),
                ),
                const SizedBox(height: 12.0),
                wrapWithModel(
                  model: _model.selectionCardModel3,
                  updateCallback: () => safeSetState(() {}),
                  child: SelectionCardWidget(
                    desc: 'High intensity interval training',
                    icon: Icon(
                      Icons.fitness_center_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    label: 'HIIT',
                    selected: false,
                  ),
                ),
                const SizedBox(height: 32.0),
                wrapWithModel(
                  model: _model.stepHeaderModel2,
                  updateCallback: () => safeSetState(() {}),
                  child: StepHeaderWidget(
                    bg: FlutterFlowTheme.of(context).primaryContainer,
                    number: '2',
                    subtitle: 'How long was the session?',
                    textColor: FlutterFlowTheme.of(context).onPrimaryContainer,
                    title: 'Duration',
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    _durationChip('15 min'),
                    const SizedBox(width: 12.0),
                    _durationChip('30 min', selected: true),
                    const SizedBox(width: 12.0),
                    _durationChip('45+ min'),
                  ],
                ),
                const SizedBox(height: 32.0),
                wrapWithModel(
                  model: _model.stepHeaderModel3,
                  updateCallback: () => safeSetState(() {}),
                  child: StepHeaderWidget(
                    bg: FlutterFlowTheme.of(context).primaryContainer,
                    number: '3',
                    subtitle: 'Enter your BPM readings',
                    textColor: FlutterFlowTheme.of(context).onPrimaryContainer,
                    title: 'Recovery Data',
                  ),
                ),
                const SizedBox(height: 16.0),
                _inputSection(),
                const SizedBox(height: 32.0),
                StepHeaderWidget(
                  bg: FlutterFlowTheme.of(context).primaryContainer,
                  number: '4',
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