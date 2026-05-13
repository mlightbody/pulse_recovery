import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
  })  : color = color ?? 'secondary',
        idBar = idBar ?? 'b1',
        idTxt = idTxt ?? 't1',
        label = label ?? 'Poor',
        isActive = isActive ?? false;

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0x00000000)
                : FlutterFlowTheme.of(context).alternate,
            borderRadius: BorderRadius.circular(9999.0),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.dmSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: widget.isActive
                    ? FlutterFlowTheme.of(context).primaryText
                    : FlutterFlowTheme.of(context).accent3,
                letterSpacing: 0.0,
                lineHeight: 1.2,
              ),
        ),
      ],
    );
  }
}