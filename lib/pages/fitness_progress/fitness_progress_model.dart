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
import 'fitness_progress_widget.dart' show FitnessProgressWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FitnessProgressModel extends FlutterFlowModel<FitnessProgressWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TabGroup.
  late TabGroupModel tabGroupModel;
  // Model for TrendStat.
  late TrendStatModel trendStatModel1;
  // Model for TrendStat.
  late TrendStatModel trendStatModel2;
  // Model for Button.
  late ButtonModel buttonModel;
  // Model for HistoryCard.
  late HistoryCardModel historyCardModel1;
  // Model for HistoryCard.
  late HistoryCardModel historyCardModel2;
  // Model for HistoryCard.
  late HistoryCardModel historyCardModel3;

  @override
  void initState(BuildContext context) {
    tabGroupModel = createModel(context, () => TabGroupModel());
    trendStatModel1 = createModel(context, () => TrendStatModel());
    trendStatModel2 = createModel(context, () => TrendStatModel());
    buttonModel = createModel(context, () => ButtonModel());
    historyCardModel1 = createModel(context, () => HistoryCardModel());
    historyCardModel2 = createModel(context, () => HistoryCardModel());
    historyCardModel3 = createModel(context, () => HistoryCardModel());
  }

  @override
  void dispose() {
    tabGroupModel.dispose();
    trendStatModel1.dispose();
    trendStatModel2.dispose();
    buttonModel.dispose();
    historyCardModel1.dispose();
    historyCardModel2.dispose();
    historyCardModel3.dispose();
  }
}
