import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'band_indicator_model.dart';
export 'band_indicator_model.dart';

class BandIndicatorWidget extends StatefulWidget {
  const BandIndicatorWidget({
    super.key,
    String? color,
    String? idBar,
    String? idTxt,
    String? label,
    bool? isActive,
  })  : this.color = color ?? 'secondary',
        this.idBar = idBar ?? 'b1',
        this.idTxt = idTxt ?? 't1',
        this.label = label ?? 'Poor',
        this.isActive = isActive ?? false;

  final String color;
  final String idBar;
  final String idTxt;
  final String label;
  final bool isActive;

  @override
  State<BandIndicatorWidget> createState() => _BandIndicatorWidgetState();
}

class _BandIndicatorWidgetState extends State<BandIndicatorWidget> {
  late BandIndicatorModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BandIndicatorModel());
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
        Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: widget!.isActive
                ? Color(0x00000000)
                : FlutterFlowTheme.of(context).alternate,
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
          ),
        ),
        Text(
          valueOrDefault<String>(
            widget!.label,
            'Poor',
          ),
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.dmSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: widget!.isActive
                    ? FlutterFlowTheme.of(context).primaryText
                    : FlutterFlowTheme.of(context).accent3,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.2,
              ),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}
