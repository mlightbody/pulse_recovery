import '/components/button/button_widget.dart';
import '/components/history_item/history_item_widget.dart';
import '/components/metric_card/metric_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, Athlete',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.55,
                                    ),
                              ),
                              Text(
                                'Vigor Recovery',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.25,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            context.goNamed(ProfileSettingsWidget.routeName);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9999.0),
                            child: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).tertiary,
                                borderRadius: BorderRadius.circular(9999.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  width: 2.0,
                                ),
                              ),
                              child: CachedNetworkImage(
                                fadeInDuration:
                                    const Duration(milliseconds: 0),
                                fadeOutDuration:
                                    const Duration(milliseconds: 0),
                                imageUrl:
                                    'https://dimg.dreamflow.cloud/v1/image/minimalist%20hand%20drawn%20person%20avatar',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// Latest Assessment
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Latest Assessment',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          font: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .onPrimaryContainer,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .onPrimaryContainer20,
                                    borderRadius: BorderRadius.circular(9999.0),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                      12.0,
                                      8.0,
                                      12.0,
                                      8.0,
                                    ),
                                    child: Text(
                                      'Excellent',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .onPrimary,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.2,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '42%',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        font: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w900,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimaryContainer,
                                        fontSize: 64.0,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.2,
                                      ),
                                ),
                                Text(
                                  'Heart Rate Recovery',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.dmSans(),
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimaryContainer80,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.55,
                                      ),
                                ),
                              ].divide(const SizedBox(height: 4.0)),
                            ),
                            InkWell(
                              onTap: () {
                                context.goNamed(NewAssessmentWidget.routeName);
                              },
                              borderRadius: BorderRadius.circular(32.0),
                              child: wrapWithModel(
                                model: _model.buttonModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: ButtonWidget(
                                  content: 'Start New Assessment',
                                  icon: Icon(
                                    Icons.play_arrow_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).onPrimary,
                                    size: 16.0,
                                  ),
                                  iconPresent: true,
                                  iconEndPresent: false,
                                  variant: 'primary',
                                  size: 'large',
                                  fullWidth: true,
                                  loading: false,
                                  disabled: false,
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(height: 24.0)),
                        ),
                      ),
                    ),

                    /// Metric cards - responsive fix for overflow
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useSingleColumn = constraints.maxWidth < 420;
                        final cardWidth = useSingleColumn
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 16.0) / 2;

                        return Wrap(
                          spacing: 16.0,
                          runSpacing: 16.0,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: wrapWithModel(
                                model: _model.metricCardModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: MetricCardWidget(
                                  icon: Icon(
                                    Icons.favorite_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 18.0,
                                  ),
                                  label: 'Avg. Recovery',
                                  value: '34%',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: wrapWithModel(
                                model: _model.metricCardModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: MetricCardWidget(
                                  icon: Icon(
                                    Icons.history_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 18.0,
                                  ),
                                  label: 'Total Tests',
                                  value: '12',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    /// Recovery Trend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recovery Trend',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Flexible(
                              flex: 0,
                              child: InkWell(
                                onTap: () {
                                  context.goNamed(
                                    FitnessProgressWidget.routeName,
                                  );
                                },
                                borderRadius: BorderRadius.circular(24.0),
                                child: wrapWithModel(
                                  model: _model.buttonModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: ButtonWidget(
                                    content: 'View Graph',
                                    iconPresent: false,
                                    iconEndPresent: false,
                                    variant: 'ghost',
                                    size: 'small',
                                    fullWidth: false,
                                    loading: false,
                                    disabled: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 180.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(40.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SizedBox(
                              height: 132.0,
                              child: FlutterFlowLineChart(
                                data: [
                                  FFLineChartData(
                                    xData: const [
                                      0.0,
                                      1.0,
                                      2.0,
                                      3.0,
                                      4.0,
                                      5.0,
                                    ],
                                    yData: const [
                                      28.0,
                                      32.0,
                                      30.0,
                                      35.0,
                                      38.0,
                                      42.0,
                                    ],
                                    settings: LineChartBarData(
                                      color:
                                          FlutterFlowTheme.of(context).success,
                                      barWidth: 2.0,
                                      isCurved: true,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: FlutterFlowTheme.of(context)
                                            .success20,
                                      ),
                                    ),
                                  ),
                                ],
                                chartStylingInfo: const ChartStylingInfo(
                                  backgroundColor: Colors.transparent,
                                  showBorder: false,
                                ),
                                axisBounds: const AxisBounds(
                                  minX: 0.0,
                                  minY: 0.0,
                                  maxX: 5.0,
                                  maxY: 50.4,
                                ),
                                xLabels: const [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                ],
                                xAxisLabelInfo: AxisLabelInfo(
                                  showLabels: true,
                                  labelTextStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.dmSans(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 10.0,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.0,
                                      ),
                                  reservedSize: 28.0,
                                ),
                                yAxisLabelInfo: const AxisLabelInfo(
                                  reservedSize: 0.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ].divide(const SizedBox(height: 16.0)),
                    ),

                    /// Recent History
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Recent History',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                        ),
                        Column(
                          children: [
                            wrapWithModel(
                              model: _model.historyItemModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: HistoryItemWidget(
                                band: 'Excellent',
                                date: 'Yesterday, 4:30 PM',
                                icon: Icon(
                                  Icons.directions_run_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .onPrimaryContainer,
                                  size: 24.0,
                                ),
                                score: '42%',
                                title: 'HIIT Sprint',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.historyItemModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: HistoryItemWidget(
                                band: 'Good',
                                date: 'Oct 24, 2023',
                                icon: Icon(
                                  Icons.directions_bike_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .onPrimaryContainer,
                                  size: 24.0,
                                ),
                                score: '31%',
                                title: 'Cycling Power',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.historyItemModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: HistoryItemWidget(
                                band: 'Average',
                                date: 'Oct 20, 2023',
                                icon: Icon(
                                  Icons.self_improvement_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .onPrimaryContainer,
                                  size: 24.0,
                                ),
                                score: '22%',
                                title: 'Steady State',
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            context.goNamed(HistoryLogWidget.routeName);
                          },
                          borderRadius: BorderRadius.circular(24.0),
                          child: wrapWithModel(
                            model: _model.buttonModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              content: 'See All History',
                              iconPresent: false,
                              iconEndPresent: false,
                              variant: 'outline',
                              size: 'medium',
                              fullWidth: false,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ),
                      ].divide(const SizedBox(height: 16.0)),
                    ),

                    const SizedBox(height: 20.0),

// 🔥 LOGOUT BUTTON
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0),
  child: ElevatedButton(
    onPressed: () async {
      await FirebaseAuth.instance.signOut();
            context.go('/');
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    child: const Text(
      'Log Out',
      style: TextStyle(color: Colors.white),
    ),
  ),
),
                  ].divide(const SizedBox(height: 32.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}