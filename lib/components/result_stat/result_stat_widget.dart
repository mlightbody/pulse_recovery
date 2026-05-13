import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
  })  : idLabel = idLabel ?? 'sl1',
        idVal = idVal ?? 'sv1',
        label = label ?? 'Peak HR',
        value = value ?? '164 bpm';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.dmSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                lineHeight: 1.3,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          widget.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                lineHeight: 1.25,
              ),
        ),
      ],
    );
  }
}