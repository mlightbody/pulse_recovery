import '/components/button/button_widget.dart';
import '/components/selection_card/selection_card_widget.dart';
import '/components/step_header/step_header_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'new_assessment_widget.dart' show NewAssessmentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NewAssessmentModel extends FlutterFlowModel<NewAssessmentWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepHeader.
  late StepHeaderModel stepHeaderModel1;
  // Model for SelectionCard.
  late SelectionCardModel selectionCardModel1;
  // Model for SelectionCard.
  late SelectionCardModel selectionCardModel2;
  // Model for SelectionCard.
  late SelectionCardModel selectionCardModel3;
  // Model for StepHeader.
  late StepHeaderModel stepHeaderModel2;
  // Model for StepHeader.
  late StepHeaderModel stepHeaderModel3;
  // Model for TextField.
  late TextFieldModel textFieldModel1;
  // Model for TextField.
  late TextFieldModel textFieldModel2;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    stepHeaderModel1 = createModel(context, () => StepHeaderModel());
    selectionCardModel1 = createModel(context, () => SelectionCardModel());
    selectionCardModel2 = createModel(context, () => SelectionCardModel());
    selectionCardModel3 = createModel(context, () => SelectionCardModel());
    stepHeaderModel2 = createModel(context, () => StepHeaderModel());
    stepHeaderModel3 = createModel(context, () => StepHeaderModel());
    textFieldModel1 = createModel(context, () => TextFieldModel());
    textFieldModel2 = createModel(context, () => TextFieldModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    stepHeaderModel1.dispose();
    selectionCardModel1.dispose();
    selectionCardModel2.dispose();
    selectionCardModel3.dispose();
    stepHeaderModel2.dispose();
    stepHeaderModel3.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    buttonModel.dispose();
  }
}
