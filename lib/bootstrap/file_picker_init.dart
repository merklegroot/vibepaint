import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

void ensureFilePickerInitialized() {
  WidgetsFlutterBinding.ensureInitialized();

  // Always register the platform implementation. A generic FilePickerIO
  // instance may already be set (e.g. after hot reload) but it does not
  // implement saveFile on desktop.
  if (Platform.isMacOS) {
    FilePickerMacOS.registerWith();
  } else if (Platform.isLinux) {
    FilePickerLinux.registerWith();
  } else if (Platform.isAndroid || Platform.isIOS) {
    FilePickerIO.registerWith();
  }
}
