import '/components/button/button_widget.dart';
import '/components/history_item2/history_item2_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'history_log_widget.dart' show HistoryLogWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HistoryLogModel extends FlutterFlowModel<HistoryLogWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for HistoryItem2.
  late HistoryItem2Model historyItem2Model1;
  // Model for HistoryItem2.
  late HistoryItem2Model historyItem2Model2;
  // Model for HistoryItem2.
  late HistoryItem2Model historyItem2Model3;
  // Model for HistoryItem2.
  late HistoryItem2Model historyItem2Model4;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    historyItem2Model1 = createModel(context, () => HistoryItem2Model());
    historyItem2Model2 = createModel(context, () => HistoryItem2Model());
    historyItem2Model3 = createModel(context, () => HistoryItem2Model());
    historyItem2Model4 = createModel(context, () => HistoryItem2Model());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    historyItem2Model1.dispose();
    historyItem2Model2.dispose();
    historyItem2Model3.dispose();
    historyItem2Model4.dispose();
    buttonModel.dispose();
  }
}
