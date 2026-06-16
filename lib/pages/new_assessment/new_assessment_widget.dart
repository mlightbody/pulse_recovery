import 'dart:convert';

import '/components/button/button_widget.dart';
import '/components/step_header/step_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/models/heart_rate_sample.dart';
import '/utils/recovery_pattern.dart';
import '/utils/recovery_assessment_levels.dart';
import '/utils/recovery_decision_engine.dart';
import '/services/assessment_service.dart';
import '/models/pending_recovery_session.dart';
import '/services/recovery_assessment_service.dart';
import '/services/recovery_session_import_service.dart';
import '/services/watch_session_service.dart';
import '/widgets/recovery_curve_chart.dart';
import '/services/android_watch_session_service.dart';
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
  PendingRecoverySession? _selectedWatchSession;

  List<Map<String, dynamic>> _androidWatchSessions = [];
  bool _loadingAndroidWatchSessions = true;
  Map<String, dynamic>? _selectedAndroidWatchSession;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewAssessmentModel());
    _loadPendingSessions();
    _loadAndroidWatchSessions();
  }

  Future<void> _loadPendingSessions() async {
    final sessions = await _importService.getPendingSessions();

    if (!mounted) return;

    setState(() {
      _pendingSessions = sessions;
      _loadingWatchSessions = false;
    });
  }

  Future<void> _loadAndroidWatchSessions() async {
    final sessions = await AndroidWatchSessionService.getReceivedWatchSessions();

    if (!mounted) return;

    setState(() {
      _androidWatchSessions = sessions
          .where((session) => session['importStatus']?.toString() != 'imported')
          .toList();
      _loadingAndroidWatchSessions = false;
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
      _selectedWatchSession = session;
      _selectedAndroidWatchSession = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${session.source} values added. Now complete effort and feeling.',
        ),
      ),
    );
  }

  void _useAndroidWatchSession(Map<String, dynamic> session) {
    final peakHr = _asInt(session['peakHr']);
    final hr60 = _asInt(session['hr60']);
    final hr120 = _asInt(session['hr120']);

    if (peakHr <= 0 || hr60 <= 0 || hr120 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This Samsung watch session does not contain enough data.',
          ),
        ),
      );
      return;
    }

    final source = session['source']?.toString() ?? 'Samsung Watch';

    setState(() {
      peakHrController.text = peakHr.toString();
      hr60Controller.text = hr60.toString();
      hr120Controller.text = hr120.toString();

      _selectedSource = source;
      _selectedAndroidWatchSession = session;

      // Ensure Apple Watch selection is cleared.
      _selectedWatchSession = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$source values added. Now complete effort and feeling.',
        ),
      ),
    );
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

    final earlyRecoveryAssessment = classifyEarlyRecovery(hrr60);
    final overallRecoveryAssessment = classifyOverallRecovery(hrr120);

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
        // what happened after this recommendation.
        decisionState: recoveryDecision.state.name,
        reasonTag: recoveryDecision.reasonTag.name,
        adviceType: 'current_session',
        adviceTitle: recoveryDecision.title,
        adviceSummary: recoveryDecision.summary,
        adviceRecommendation: recoveryDecision.recommendation,

        // Raw watch session data, when available.
        // Apple Watch and Samsung Watch are both saved using the same structure:
        // heartRateSamples: [{ timestamp, bpm, phase }]
        // workoutStartedAt: DateTime
        // recoveryStartedAt: DateTime
        heartRateSamples: _selectedWatchSession?.samples ??
            (_selectedAndroidWatchSession == null
                ? null
                : _androidHeartRateSamplesFromSession(
                    _selectedAndroidWatchSession!,
                  )),
        workoutStartedAt: _selectedWatchSession?.workoutStartedAt ??
            (_selectedAndroidWatchSession == null
                ? null
                : _androidWorkoutStartedAt(
                    _selectedAndroidWatchSession!,
                  )),
        recoveryStartedAt: _selectedWatchSession?.recoveryStartedAt ??
            (_selectedAndroidWatchSession == null
                ? null
                : _androidRecoveryStartedAt(
                    _selectedAndroidWatchSession!,
                  )),
      );

      // Clear/mark the selected watch session only after the Firebase save succeeds.
      if (_selectedWatchSession != null) {
        await WatchSessionService.instance.clearLatestSession();
      }

      if (_selectedAndroidWatchSession != null) {
        final sessionId = _selectedAndroidWatchSession!['sessionId']?.toString();

        if (sessionId != null && sessionId.isNotEmpty) {
          await AndroidWatchSessionService.markWatchSessionImported(sessionId);
        }
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

    if (_selectedWatchSession != null ||
        _selectedAndroidWatchSession != null ||
        _selectedSource != null) {
      await _loadAndroidWatchSessions();

      if (!mounted) return;

      setState(() {
        _pendingSessions = [];
        _selectedSource = null;
        _selectedWatchSession = null;
        _selectedAndroidWatchSession = null;
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

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> _androidPayloadMap(Map<String, dynamic> session) {
    final payload = session['payload']?.toString();

    if (payload == null || payload.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  DateTime? _dateTimeFromMillis(dynamic value) {
    final millis = _asInt(value);

    if (millis <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  DateTime? _androidWorkoutStartedAt(Map<String, dynamic> session) {
    final payload = _androidPayloadMap(session);

    return _dateTimeFromMillis(
          session['workoutStartedAtMillis'],
        ) ??
        _dateTimeFromMillis(
          payload['workoutStartedAtMillis'],
        );
  }

  DateTime? _androidRecoveryStartedAt(Map<String, dynamic> session) {
    final payload = _androidPayloadMap(session);

    // For the Samsung watch flow, recovery starts when the workout is stopped.
    return _dateTimeFromMillis(
          session['workoutEndedAtMillis'],
        ) ??
        _dateTimeFromMillis(
          payload['workoutEndedAtMillis'],
        );
  }

  List<HeartRateSample> _androidHeartRateSamplesFromSession(
    Map<String, dynamic> session,
  ) {
    final payload = _androidPayloadMap(session);
    final rawPoints = payload['points'];

    if (rawPoints is! List) {
      return [];
    }

    final recoveryStartedAt = _androidRecoveryStartedAt(session);
    final recoveryStartedMillis = recoveryStartedAt?.millisecondsSinceEpoch;

    final samples = <HeartRateSample>[];

    for (final rawPoint in rawPoints) {
      if (rawPoint is! Map) {
        continue;
      }

      final point = Map<String, dynamic>.from(rawPoint);

      final bpmRaw = point['bpm'];
      final timestampMillis = _asInt(point['timestampMillis']);

      if (bpmRaw is! num || timestampMillis <= 0) {
        continue;
      }

      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

      final phase = recoveryStartedMillis == null
          ? null
          : timestampMillis < recoveryStartedMillis
              ? 'workout'
              : 'recovery';

      samples.add(
        HeartRateSample(
          timestamp: timestamp,
          bpm: bpmRaw.round(),
          phase: phase,
        ),
      );
    }

    samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return samples;
  }

  String _formatAndroidWatchDate(dynamic millisValue) {
    final millis = _asInt(millisValue);

    if (millis <= 0) {
      return 'Unknown time';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} ${date.hour}:$minute';
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
            if (session.samples.length >= 2) ...[
              const SizedBox(height: 16.0),
              RecoveryCurveChart(
                samples: session.samples,
                recoveryStartedAt: session.recoveryStartedAt,
              ),
            ],
            const SizedBox(height: 20.0),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _useWatchSession(session),
              child: ButtonWidget(
                content: _selectedWatchSession?.id == session.id
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

  Widget _androidWatchSessionSection() {
    if (_loadingAndroidWatchSessions) {
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

    if (_androidWatchSessions.isEmpty) {
      return const SizedBox.shrink();
    }

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
              'Samsung Watch Sessions',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Choose a received Samsung watch recovery session to fill the recovery fields below.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.55,
                  ),
            ),
            const SizedBox(height: 16.0),
            ..._androidWatchSessions.map((session) {
              final sessionId = session['sessionId']?.toString() ?? '';
              final source = session['source']?.toString() ?? 'Samsung Watch';

              final peakHr = _asInt(session['peakHr']);
              final workoutEndHr = _asInt(session['workoutEndHr']);
              final hr60 = _asInt(session['hr60']);
              final hr120 = _asInt(session['hr120']);
              final sampleCount = _asInt(session['sampleCount']);
              final receivedAt = _formatAndroidWatchDate(
                session['receivedAtMillis'],
              );

              final samsungSamples = _androidHeartRateSamplesFromSession(
                session,
              );
              final samsungRecoveryStartedAt = _androidRecoveryStartedAt(
                session,
              );

              final isSelected =
                  _selectedAndroidWatchSession?['sessionId']?.toString() ==
                      sessionId;

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isSelected
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).alternate,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      source,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Received: $receivedAt',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.dmSans(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Peak HR: ${peakHr > 0 ? peakHr : '-'}\n'
                      'Workout end HR: ${workoutEndHr > 0 ? workoutEndHr : '-'}\n'
                      '60-second HR: ${hr60 > 0 ? hr60 : '-'}\n'
                      '120-second HR: ${hr120 > 0 ? hr120 : '-'}\n'
                      'Samples: $sampleCount',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.55,
                          ),
                    ),
                    if (samsungSamples.length >= 2 &&
                        samsungRecoveryStartedAt != null) ...[
                      const SizedBox(height: 16.0),
                      RecoveryCurveChart(
                        samples: samsungSamples,
                        recoveryStartedAt: samsungRecoveryStartedAt,
                      ),
                    ],
                    const SizedBox(height: 16.0),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _useAndroidWatchSession(session),
                      child: ButtonWidget(
                        content: isSelected
                            ? 'Samsung Values Added'
                            : 'Use Samsung Watch Session',
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
              );
            }),
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
                StepHeaderWidget(
                  bg: FlutterFlowTheme.of(context).primaryContainer,
                  number: '1',
                  subtitle: 'Use a watch session or enter your BPM readings',
                  textColor: FlutterFlowTheme.of(context).onPrimaryContainer,
                  title: 'Recovery Data',
                ),
                const SizedBox(height: 16.0),
                _watchSessionSection(),
                if (_pendingSessions.isNotEmpty || _loadingWatchSessions)
                  const SizedBox(height: 16.0),
                _androidWatchSessionSection(),
                if (_androidWatchSessions.isNotEmpty ||
                    _loadingAndroidWatchSessions)
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