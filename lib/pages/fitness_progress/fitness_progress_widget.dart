import '/components/button/button_widget.dart';
import '/components/history_card/history_card_widget.dart';
import '/components/tab_group/tab_group_widget.dart';
import '/components/trend_stat/trend_stat_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'fitness_progress_model.dart';
export 'fitness_progress_model.dart';
import '/index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FitnessProgressWidget extends StatefulWidget {
  const FitnessProgressWidget({super.key});

  static String routeName = 'FitnessProgress';
  static String routePath = '/fitnessProgress';

  @override
  State<FitnessProgressWidget> createState() => _FitnessProgressWidgetState();
}

class _FitnessProgressWidgetState extends State<FitnessProgressWidget> {
  late FitnessProgressModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FitnessProgressModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            context.goNamed(NewAssessmentWidget.routeName);
          },
          backgroundColor: FlutterFlowTheme.of(context).success,
          icon: Icon(
            Icons.add_rounded,
            color: FlutterFlowTheme.of(context).onPrimary,
            size: 24.0,
          ),
          elevation: 0.0,
          label: Text(
            'New Assessment',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).onPrimary,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  lineHeight: 1.3,
                ),
          ),
        ),
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopupMenuButton<String>(
  icon: Icon(Icons.menu_rounded),
  onSelected: (value) {
    switch (value) {
      case 'home':
        context.goNamed(OnboardingWidget.routeName);
        break;
      case 'dashboard':
        context.pushNamed(DashboardWidget.routeName);
        break;
      case 'new':
        context.pushNamed(NewAssessmentWidget.routeName);
        break;
      case 'result':
        context.pushNamed(AssessmentResultWidget.routeName);
        break;
      case 'progress':
        context.pushNamed(FitnessProgressWidget.routeName);
        break;
      case 'history':
        context.pushNamed(HistoryLogWidget.routeName);
        break;
      case 'settings':
        context.pushNamed(ProfileSettingsWidget.routeName);
        break;
    }
  },
  itemBuilder: (context) => const [
    PopupMenuItem(value: 'home', child: Text('Home')),
    PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
    PopupMenuItem(value: 'new', child: Text('New Assessment')),
    PopupMenuItem(value: 'result', child: Text('Assessment Result')),
    PopupMenuItem(value: 'progress', child: Text('Fitness Progress')),
    PopupMenuItem(value: 'history', child: Text('History Log')),
    PopupMenuItem(value: 'settings', child: Text('Profile Settings')),
  ],
),
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Progress',
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                      lineHeight: 1.25,
                                    ),
                              ),
                              Text(
                                'Aerobic recovery trends',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.55,
                                    ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                          FlutterFlowIconButton(
                            borderRadius: 32.0,
                            borderWidth: 1.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            icon: Icon(
                              Icons.settings_rounded,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            onPressed: () {
                              print('IconButton pressed ...');
                            },
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(32.0),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Recovery Drop %',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                    wrapWithModel(
                                      model: _model.tabGroupModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: TabGroupWidget(
                                        label1: 'Week',
                                        label2: 'Month',
                                        label2Present: true,
                                        label3: 'Year',
                                        label3Present: true,
                                        label4: '',
                                        label4Present: false,
                                        label5: '',
                                        label5Present: false,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 220.0,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    child: Container(
                                      child: Container(
                                        height: 220.0,
                                        child: FlutterFlowLineChart(
                                          data: [
                                            FFLineChartData(
                                              xData: ([
                                                0.0,
                                                1.0,
                                                2.0,
                                                3.0,
                                                4.0,
                                                5.0,
                                                6.0
                                              ])!,
                                              yData: ([
                                                22.0,
                                                28.0,
                                                25.0,
                                                32.0,
                                                30.0,
                                                38.0,
                                                35.0
                                              ])!,
                                              settings: LineChartBarData(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                barWidth: 4.0,
                                                isCurved: true,
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .success10,
                                                ),
                                              ),
                                            )
                                          ],
                                          chartStylingInfo: ChartStylingInfo(
                                            backgroundColor: Colors.transparent,
                                            showBorder: false,
                                          ),
                                          axisBounds: AxisBounds(
                                            minX: 0.0,
                                            minY: 0.0,
                                            maxX: 6.0,
                                            maxY: 45.6,
                                          ),
                                          xLabels: ([
                                            'M',
                                            'T',
                                            'W',
                                            'T',
                                            'F',
                                            'S',
                                            'S'
                                          ])!,
                                          xAxisLabelInfo: AxisLabelInfo(
                                            showLabels: true,
                                            labelTextStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.dmSans(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      fontSize: 10.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                      lineHeight: 1.0,
                                                    ),
                                            reservedSize: 28.0,
                                          ),
                                          yAxisLabelInfo: AxisLabelInfo(
                                            reservedSize: 0.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.trendStatModel1,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TrendStatWidget(
                                          icon: Icon(
                                            Icons.trending_up_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .success,
                                            size: 18.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .success,
                                          label: 'Avg. Drop',
                                          value: '31%',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.trendStatModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TrendStatWidget(
                                          icon: Icon(
                                            Icons.star_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                            size: 18.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondary,
                                          label: 'Best',
                                          value: '42%',
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ].divide(SizedBox(height: 24.0)),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(40.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).tertiary,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.lightbulb_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).onAccent,
                                    size: 20.0,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Consistency pays off!',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                              lineHeight: 1.3,
                                            ),
                                      ),
                                      Text(
                                        'Your recovery rate has improved by 12% since last month. Keep it up!',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 4.0)),
                                  ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Recent Assessments',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              wrapWithModel(
                                model: _model.buttonModel,
                                updateCallback: () => safeSetState(() {}),
                                child: ButtonWidget(
                                  content: 'See All',
                                  iconPresent: false,
                                  iconEndPresent: false,
                                  variant: 'ghost',
                                  size: 'small',
                                  fullWidth: false,
                                  loading: false,
                                  disabled: false,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              wrapWithModel(
                                model: _model.historyCardModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: HistoryCardWidget(
                                  bandColor:
                                      FlutterFlowTheme.of(context).success,
                                  bandLabel: 'Excellent',
                                  date: 'Oct 24, 2023 • 20 min',
                                  drop: '38',
                                  exercise: 'Steady Jog',
                                  exerciseIcon: Icon(
                                    Icons.directions_run_rounded,
                                    color: FlutterFlowTheme.of(context).success,
                                    size: 26.0,
                                  ),
                                ),
                              ),
                              wrapWithModel(
                                model: _model.historyCardModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: HistoryCardWidget(
                                  bandColor:
                                      FlutterFlowTheme.of(context).tertiary,
                                  bandLabel: 'Good',
                                  date: 'Oct 22, 2023 • 15 min',
                                  drop: '29',
                                  exercise: 'Cycling Hiit',
                                  exerciseIcon: Icon(
                                    Icons.directions_bike_rounded,
                                    color: FlutterFlowTheme.of(context).success,
                                    size: 26.0,
                                  ),
                                ),
                              ),
                              wrapWithModel(
                                model: _model.historyCardModel3,
                                updateCallback: () => safeSetState(() {}),
                                child: HistoryCardWidget(
                                  bandColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  bandLabel: 'Average',
                                  date: 'Oct 20, 2023 • 30 min',
                                  drop: '22',
                                  exercise: 'Power Walk',
                                  exerciseIcon: Icon(
                                    Icons.directions_walk_rounded,
                                    color: FlutterFlowTheme.of(context).success,
                                    size: 26.0,
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                      Container(
                        height: 80.0,
                      ),
                    ].divide(SizedBox(height: 24.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
