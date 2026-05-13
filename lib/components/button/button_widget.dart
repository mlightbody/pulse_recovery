import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'button_model.dart';
export 'button_model.dart';

class ButtonWidget extends StatefulWidget {
  const ButtonWidget({
    super.key,
    String? content,
    this.icon,
    bool? iconPresent,
    this.iconEnd,
    bool? iconEndPresent,
    String? variant,
    String? size,
    bool? fullWidth,
    bool? loading,
    bool? disabled,
  })  : content = content ?? 'Skip',
        iconPresent = iconPresent ?? false,
        iconEndPresent = iconEndPresent ?? false,
        variant = variant ?? 'ghost',
        size = size ?? 'medium',
        fullWidth = fullWidth ?? false,
        loading = loading ?? false,
        disabled = disabled ?? false;

  final String content;
  final Widget? icon;
  final bool iconPresent;
  final Widget? iconEnd;
  final bool iconEndPresent;
  final String variant;
  final String size;
  final bool fullWidth;
  final bool loading;
  final bool disabled;

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  late ButtonModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Color _backgroundColor(BuildContext context) {
    if (widget.variant == 'secondary') {
      return FlutterFlowTheme.of(context).secondary;
    } else if (widget.variant == 'outline' || widget.variant == 'ghost') {
      return Colors.transparent;
    } else if (widget.variant == 'destructive') {
      return FlutterFlowTheme.of(context).error;
    }
    return FlutterFlowTheme.of(context).primary;
  }

  Color _textColor(BuildContext context) {
    if (widget.variant == 'secondary') {
      return FlutterFlowTheme.of(context).onSecondary;
    } else if (widget.variant == 'outline') {
      return FlutterFlowTheme.of(context).primaryText;
    } else if (widget.variant == 'ghost') {
      return FlutterFlowTheme.of(context).primary;
    } else if (widget.variant == 'destructive') {
      return FlutterFlowTheme.of(context).onError;
    }
    return FlutterFlowTheme.of(context).onPrimary;
  }

  double _radius() {
    if (widget.size == 'small') return 12.0;
    if (widget.size == 'large') return 32.0;
    return 20.0;
  }

  double _horizontalPadding() {
    if (widget.size == 'small') return 16.0;
    if (widget.size == 'large') return 32.0;
    return 24.0;
  }

  double _verticalPadding() {
    if (widget.size == 'small') return 4.0;
    if (widget.size == 'large') return 16.0;
    return 8.0;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.55 : 1.0,
      child: Container(
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(_radius()),
          border: Border.all(
            color: widget.variant == 'outline'
                ? FlutterFlowTheme.of(context).alternate
                : Colors.transparent,
            width: widget.variant == 'outline' ? 1.0 : 0.0,
          ),
        ),
        child: Stack(
          alignment: const AlignmentDirectional(0.0, 0.0),
          children: [
            Opacity(
              opacity: widget.loading ? 0.0 : 1.0,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  _horizontalPadding(),
                  _verticalPadding(),
                  _horizontalPadding(),
                  _verticalPadding(),
                ),
                child: Row(
                  mainAxisSize:
                      widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.iconPresent && widget.icon != null) widget.icon!,
                    if (widget.iconPresent && widget.icon != null)
                      const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        widget.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style:
                            FlutterFlowTheme.of(context).labelMedium.override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                                  color: _textColor(context),
                                  letterSpacing: 0.0,
                                  lineHeight: 1.3,
                                ),
                      ),
                    ),
                    if (widget.iconEndPresent && widget.iconEnd != null)
                      const SizedBox(width: 8.0),
                    if (widget.iconEndPresent && widget.iconEnd != null)
                      widget.iconEnd!,
                  ],
                ),
              ),
            ),
            if (widget.loading)
              CircularPercentIndicator(
                percent: 0.0,
                radius: 7.0,
                lineWidth: 2.0,
                animation: true,
                animateFromLastPercent: true,
                progressColor: _textColor(context),
                backgroundColor: FlutterFlowTheme.of(context).alternate,
              ),
          ],
        ),
      ),
    );
  }
}