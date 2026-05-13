import '/components/button/button_widget.dart';
import '/components/history_item/history_item_widget.dart';
import '/components/metric_card/metric_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'dashboard_widget.dart' show DashboardWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashboardModel extends FlutterFlowModel<DashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for MetricCard.
  late MetricCardModel metricCardModel1;
  // Model for MetricCard.
  late MetricCardModel metricCardModel2;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for HistoryItem.
  late HistoryItemModel historyItemModel1;
  // Model for HistoryItem.
  late HistoryItemModel historyItemModel2;
  // Model for HistoryItem.
  late HistoryItemModel historyItemModel3;
  // Model for Button.
  late ButtonModel buttonModel3;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => ButtonModel());
    metricCardModel1 = createModel(context, () => MetricCardModel());
    metricCardModel2 = createModel(context, () => MetricCardModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    historyItemModel1 = createModel(context, () => HistoryItemModel());
    historyItemModel2 = createModel(context, () => HistoryItemModel());
    historyItemModel3 = createModel(context, () => HistoryItemModel());
    buttonModel3 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    metricCardModel1.dispose();
    metricCardModel2.dispose();
    buttonModel2.dispose();
    historyItemModel1.dispose();
    historyItemModel2.dispose();
    historyItemModel3.dispose();
    buttonModel3.dispose();
  }
}
