import '/components/band_indicator/band_indicator_widget.dart';
import '/components/button/button_widget.dart';
import '/components/pie_chart/pie_chart_widget.dart';
import '/components/result_stat/result_stat_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'assessment_result_widget.dart' show AssessmentResultWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AssessmentResultModel extends FlutterFlowModel<AssessmentResultWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PieChart.
  late PieChartModel pieChartModel;
  // Model for BandIndicator.
  late BandIndicatorModel bandIndicatorModel1;
  // Model for BandIndicator.
  late BandIndicatorModel bandIndicatorModel2;
  // Model for BandIndicator.
  late BandIndicatorModel bandIndicatorModel3;
  // Model for BandIndicator.
  late BandIndicatorModel bandIndicatorModel4;
  // Model for BandIndicator.
  late BandIndicatorModel bandIndicatorModel5;
  // Model for ResultStat.
  late ResultStatModel resultStatModel1;
  // Model for ResultStat.
  late ResultStatModel resultStatModel2;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    pieChartModel = createModel(context, () => PieChartModel());
    bandIndicatorModel1 = createModel(context, () => BandIndicatorModel());
    bandIndicatorModel2 = createModel(context, () => BandIndicatorModel());
    bandIndicatorModel3 = createModel(context, () => BandIndicatorModel());
    bandIndicatorModel4 = createModel(context, () => BandIndicatorModel());
    bandIndicatorModel5 = createModel(context, () => BandIndicatorModel());
    resultStatModel1 = createModel(context, () => ResultStatModel());
    resultStatModel2 = createModel(context, () => ResultStatModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    pieChartModel.dispose();
    bandIndicatorModel1.dispose();
    bandIndicatorModel2.dispose();
    bandIndicatorModel3.dispose();
    bandIndicatorModel4.dispose();
    bandIndicatorModel5.dispose();
    resultStatModel1.dispose();
    resultStatModel2.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
