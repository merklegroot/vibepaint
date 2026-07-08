import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('vibepaint/native_save_dialog');

bool get supportsNativeSaveFormatPicker =>
    Platform.isMacOS || Platform.isWindows;

Future<String?> showNativeSaveDialog({
  required String fileName,
  String? initialDirectory,
  String dialogTitle = 'Save As',
}) async {
  if (!supportsNativeSaveFormatPicker) {
    return null;
  }

  try {
    return await _channel.invokeMethod<String>('showSaveDialog', {
      'fileName': fileName,
      'initialDirectory': initialDirectory,
      'dialogTitle': dialogTitle,
    });
  } on PlatformException {
    return null;
  } catch (_) {
    return null;
  }
}
