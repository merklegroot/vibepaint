import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

MenuSerializableShortcut platformMenuShortcut(
  LogicalKeyboardKey key, {
  bool shift = false,
}) {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return SingleActivator(key, meta: true, shift: shift);
  }
  return SingleActivator(key, control: true, shift: shift);
}

bool get useInWindowFileMenu => defaultTargetPlatform != TargetPlatform.macOS;

bool get usePlatformFileMenu => defaultTargetPlatform == TargetPlatform.macOS;
