import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'result_stat_model.dart';
export 'result_stat_model.dart';

class ResultStatWidget extends StatefulWidget {
  const ResultStatWidget({
    super.key,
    String? idLabel,
    String? idVal,
    String? label,
    String? value,
  })  : this.idLabel = idLabel ?? 'sl1',
        this.idVal = idVal ?? 'sv1',
        this.label = label ?? 'Peak HR',
        this.value = value ?? '164 bpm';

  final String idLabel;
  final String idVal;
  final String label;
  final String value;

  @override
  State<ResultStatWidget> createState() => _ResultStatWidgetState();
}

class _ResultStatWidgetState extends State<ResultStatWidget> {
  late ResultStatModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ResultStatModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          valueOrDefault<String>(
            widget!.label,
            'Peak HR',
          ),
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.dmSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.3,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget!.value,
            '164 bpm',
          ),
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
                fontStyle:
                    FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                lineHeight: 1.25,
              ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
