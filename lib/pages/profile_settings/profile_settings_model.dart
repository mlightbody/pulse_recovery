import '/components/button/button_widget.dart';
import '/components/preference_toggle/preference_toggle_widget.dart';
import '/components/profile_header/profile_header_widget.dart';
import '/components/setting_tile/setting_tile_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'profile_settings_widget.dart' show ProfileSettingsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileSettingsModel extends FlutterFlowModel<ProfileSettingsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ProfileHeader.
  late ProfileHeaderModel profileHeaderModel;
  // Model for SettingTile.
  late SettingTileModel settingTileModel1;
  // Model for SettingTile.
  late SettingTileModel settingTileModel2;
  // Model for PreferenceToggle.
  late PreferenceToggleModel preferenceToggleModel1;
  // Model for PreferenceToggle.
  late PreferenceToggleModel preferenceToggleModel2;
  // Model for SettingTile.
  late SettingTileModel settingTileModel3;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    profileHeaderModel = createModel(context, () => ProfileHeaderModel());
    settingTileModel1 = createModel(context, () => SettingTileModel());
    settingTileModel2 = createModel(context, () => SettingTileModel());
    preferenceToggleModel1 =
        createModel(context, () => PreferenceToggleModel());
    preferenceToggleModel2 =
        createModel(context, () => PreferenceToggleModel());
    settingTileModel3 = createModel(context, () => SettingTileModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    profileHeaderModel.dispose();
    settingTileModel1.dispose();
    settingTileModel2.dispose();
    preferenceToggleModel1.dispose();
    preferenceToggleModel2.dispose();
    settingTileModel3.dispose();
    buttonModel.dispose();
  }
}
