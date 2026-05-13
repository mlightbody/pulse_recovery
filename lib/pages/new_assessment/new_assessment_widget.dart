import '/components/button/button_widget.dart';
import '/components/selection_card/selection_card_widget.dart';
import '/components/step_header/step_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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
  final recoveryHrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewAssessmentModel());
  }

  @override
  void dispose() {
    peakHrController.dispose();
    recoveryHrController.dispose();
    _model.dispose();
    super.dispose();
  }

  String _classificationFor(double recoveryPercent) {
    if (recoveryPercent < 15) return 'Poor';
    if (recoveryPercent < 25) return 'Fair';
    if (recoveryPercent < 35) return 'Average';
    if (recoveryPercent < 45) return 'Good';
    return 'Elite';
  }

  void _generateAssessment() {
    final peakHr = int.tryParse(peakHrController.text.trim());
    final recoveryHr = int.tryParse(recoveryHrController.text.trim());

    if (peakHr == null || recoveryHr == null || peakHr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid heart rate values.'),
        ),
      );
      return;
    }

    if (recoveryHr >= peakHr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery HR should be lower than peak HR.'),
        ),
      );
      return;
    }

    final drop = peakHr - recoveryHr;
    final recoveryPercent = (drop / peakHr) * 100;
    final classification = _classificationFor(recoveryPercent);

    context.goNamed(
      AssessmentResultWidget.routeName,
      queryParameters: {
        'peakHr': serializeParam(peakHr, ParamType.int),
        'recoveryHr': serializeParam(recoveryHr, ParamType.int),
        'recoveryPercent': serializeParam(recoveryPercent, ParamType.double),
        'classification': serializeParam(classification, ParamType.String),
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
                    PopupMenuItem(
                        value: 'dashboard', child: Text('Dashboard')),
                    PopupMenuItem(
                        value: 'new', child: Text('New Assessment')),
                    PopupMenuItem(
                        value: 'result', child: Text('Assessment Result')),
                    PopupMenuItem(
                        value: 'progress', child: Text('Fitness Progress')),
                    PopupMenuItem(value: 'history', child: Text('History Log')),
                    PopupMenuItem(
                        value: 'settings', child: Text('Profile Settings')),
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
                  'Measure your heart rate recovery to track aerobic fitness.',
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

                Container(
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
                          style:
                              FlutterFlowTheme.of(context).labelLarge.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(context).primaryText,
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
                          '2-Minute Recovery HR',
                          style:
                              FlutterFlowTheme.of(context).labelLarge.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(context).primaryText,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.3,
                                  ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: recoveryHrController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            hint: 'e.g. 130',
                            helper: 'BPM after 2 minutes of rest',
                            icon: Icons.favorite_border_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32.0),

                InkWell(
                  onTap: _generateAssessment,
                  borderRadius: BorderRadius.circular(32.0),
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