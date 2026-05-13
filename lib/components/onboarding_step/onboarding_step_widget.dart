import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'onboarding_step_model.dart';
export 'onboarding_step_model.dart';

class OnboardingStepWidget extends StatefulWidget {
  const OnboardingStepWidget({
    super.key,
    String? animationDesc,
    Color? blobBg,
    String? subtitle,
    String? title,
  })  : this.animationDesc = animationDesc ??
            'https://dimg.dreamflow.cloud/v1/lottie/peaceful+person+breathing+deeply+and+calmly',
        this.blobBg = blobBg ?? const Color(0x00000000),
        this.subtitle = subtitle ??
            'Heart rate recovery is a powerful window into your aerobic fitness and cardiac health.',
        this.title = title ?? 'Listen to Your Heart';

  final String animationDesc;
  final Color blobBg;
  final String subtitle;
  final String title;

  @override
  State<OnboardingStepWidget> createState() => _OnboardingStepWidgetState();
}

class _OnboardingStepWidgetState extends State<OnboardingStepWidget> {
  late OnboardingStepModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingStepModel());
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
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(140.0),
            topRight: Radius.circular(100.0),
            bottomLeft: Radius.circular(160.0),
            bottomRight: Radius.circular(120.0),
          ),
          child: Container(
            width: 280.0,
            height: 280.0,
            decoration: BoxDecoration(
              color: valueOrDefault<Color>(
                widget!.blobBg,
                FlutterFlowTheme.of(context).accent40,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(140.0),
                topRight: Radius.circular(100.0),
                bottomLeft: Radius.circular(160.0),
                bottomRight: Radius.circular(120.0),
              ),
              shape: BoxShape.rectangle,
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Lottie.network(
              valueOrDefault<String>(
                widget!.animationDesc,
                'https://dimg.dreamflow.cloud/v1/lottie/peaceful+person+breathing+deeply+and+calmly',
              ),
              width: 220.0,
              height: 220.0,
              fit: BoxFit.contain,
              animate: true,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              valueOrDefault<String>(
                widget!.title,
                'Listen to Your Heart',
              ),
              textAlign: TextAlign.center,
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
            Text(
              valueOrDefault<String>(
                widget!.subtitle,
                'Heart rate recovery is a powerful window into your aerobic fitness and cardiac health.',
              ),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.dmSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    lineHeight: 1.5,
                  ),
            ),
          ].divide(SizedBox(height: 16.0)),
        ),
      ].divide(SizedBox(height: 24.0)),
    );
  }
}
