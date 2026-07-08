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

/// macOS injects AutoFill, Dictation, and Emoji items into any menu titled
/// exactly "Edit". A zero-width space keeps the label visually identical.
String get platformEditMenuLabel =>
    defaultTargetPlatform == TargetPlatform.macOS ? 'Edit\u200B' : 'Edit';

/// Primary modifier label for UI hints (`⌘` on macOS, `Ctrl` elsewhere).
String get platformCommandLabel =>
    defaultTargetPlatform == TargetPlatform.macOS ? '⌘' : 'Ctrl';

ShortcutActivator platformKeyShortcut(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool control = false,
  bool alt = false,
}) {
  return platformMenuShortcut(
    key,
    shift: shift,
    control: control,
    alt: alt,
  );
}

/// Zoom in: ⌘= on macOS, Ctrl+= on Windows/Linux.
ShortcutActivator get platformZoomInShortcut =>
    platformKeyShortcut(LogicalKeyboardKey.equal);

/// Zoom in via the + key (Shift+=).
ShortcutActivator get platformZoomInPlusShortcut =>
    platformKeyShortcut(LogicalKeyboardKey.equal, shift: true);

/// Zoom out: ⌘- on macOS, Ctrl+- on Windows/Linux.
ShortcutActivator get platformZoomOutShortcut =>
    platformKeyShortcut(LogicalKeyboardKey.minus);

/// Fit canvas to window: ⌘0 on macOS, Ctrl+0 on Windows/Linux.
ShortcutActivator get platformZoomFitShortcut =>
    platformKeyShortcut(LogicalKeyboardKey.digit0);

/// Actual size (100%): ⌘1 on macOS, Ctrl+1 on Windows/Linux.
ShortcutActivator get platformZoomActualSizeShortcut =>
    platformKeyShortcut(LogicalKeyboardKey.digit1);

/// Numpad shortcut with the platform zoom modifier (⌘ or Ctrl).
ShortcutActivator platformZoomNumpadShortcut(LogicalKeyboardKey key) {
  return platformKeyShortcut(key);
}

String get platformZoomKeyboardHint =>
    defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘+/- zoom · ⌘0 fit · ⌘1 100%'
        : 'Ctrl+/- zoom · Ctrl+0 fit · Ctrl+1 100%';
