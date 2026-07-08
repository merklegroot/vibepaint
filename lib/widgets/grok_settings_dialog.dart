import 'package:flutter/material.dart';
import 'package:vibepaint/widgets/ai_enhance_settings_dialog.dart';

export 'package:vibepaint/widgets/ai_enhance_settings_dialog.dart'
    show showAiEnhanceSettingsDialog;

/// Opens the Grok API key settings dialog.
Future<void> showGrokSettingsDialog(BuildContext context) {
  return showAiEnhanceSettingsDialog(context);
}
