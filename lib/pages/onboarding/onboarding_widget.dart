import '/components/button/button_widget.dart';
import '/components/onboarding_step/onboarding_step_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'onboarding_model.dart';
export 'onboarding_model.dart';

class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({super.key});

  static String routeName = 'Onboarding';
  static String routePath = '/onboarding';

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  late OnboardingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _navigateFromMenu(String value) {
    switch (value) {
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
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 🔹 Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: FlutterFlowTheme.of(context).onSurface,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vigor',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w800),
                                  color: FlutterFlowTheme.of(context)
                                      .onBackground,
                                ),
                      ),
                    ],
                  ),

                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: FlutterFlowTheme.of(context).onBackground,
                    ),
                    onSelected: _navigateFromMenu,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'dashboard',
                        child: Text('Dashboard'),
                      ),
                      PopupMenuItem(
                        value: 'new',
                        child: Text('New Assessment'),
                      ),
                      PopupMenuItem(
                        value: 'result',
                        child: Text('Assessment Result'),
                      ),
                      PopupMenuItem(
                        value: 'progress',
                        child: Text('Fitness Progress'),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: Text('History Log'),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text('Profile Settings'),
                      ),
                    ],
                  ),
                ],
              ),

              /// 🔹 Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      wrapWithModel(
                        model: _model.onboardingStepModel,
                        updateCallback: () => safeSetState(() {}),
                        child: OnboardingStepWidget(
                          animationDesc:
                              'https://dimg.dreamflow.cloud/v1/lottie/peaceful+person+breathing+deeply+and+calmly',
                          blobBg: FlutterFlowTheme.of(context).accent40,
                          subtitle:
                              'Heart rate recovery is a powerful window into your aerobic fitness and cardiac health.',
                          title: 'Listen to Your Heart',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              /// 🔹 Bottom Section
              Column(
                children: [
                  /// Get Started Button
                  InkWell(
                    onTap: () {
                      context.goNamed(DashboardWidget.routeName);
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            color: FlutterFlowTheme.of(context).success20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: wrapWithModel(
                        model: _model.buttonModel2,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonWidget(
                          content: 'Get Started',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: true,
                          loading: false,
                          disabled: false,
                          iconPresent: false,
                          iconEndPresent: false,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Info Row (FIXED)
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).accent20,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your data is stored locally and securely.',
                            softWrap: true,
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}