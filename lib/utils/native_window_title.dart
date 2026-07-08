import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

Future<void> syncNativeWindowTitle(String title) async {
  if (kIsWeb) {
    return;
  }

  try {
    await windowManager.setTitle(title);
  } on Object {
    // No-op in widget tests and other headless environments.
  }
}

Future<void> ensureNativeWindowManager() async {
  if (kIsWeb) {
    return;
  }

  try {
    await windowManager.ensureInitialized();
  } on Object {
    // No-op in widget tests.
  }
}
