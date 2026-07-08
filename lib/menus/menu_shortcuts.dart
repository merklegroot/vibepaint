import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

MenuSerializableShortcut platformMenuShortcut(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool control = false,
  bool alt = false,
}) {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return SingleActivator(
      key,
      meta: !control && !alt,
      control: control,
      shift: shift,
      alt: alt,
    );
  }
  return SingleActivator(
    key,
    control: control || !alt,
    shift: shift,
    alt: alt,
  );
}

bool get useInWindowFileMenu => defaultTargetPlatform != TargetPlatform.macOS;

bool get usePlatformFileMenu => defaultTargetPlatform == TargetPlatform.macOS;
