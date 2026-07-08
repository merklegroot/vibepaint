import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/utils/selection_handles.dart';

const _channel = MethodChannel('vibepaint/selection_cursor');

bool get _usesNativeCornerCursors => !kIsWeb && Platform.isMacOS;

String? _activeMacosCursorKind;

/// Applies platform-appropriate resize cursors for selection handles.
class SelectionCursors {
  const SelectionCursors._();

  static MouseCursor mouseCursorFor(SelectionResizeHandle handle) {
    if (_usesNativeCornerCursors && isCornerSelectionHandle(handle)) {
      return MouseCursor.defer;
    }
    return cursorForSelectionHandle(handle);
  }

  static void applyForHandle(SelectionResizeHandle handle) {
    if (!_usesNativeCornerCursors || !isCornerSelectionHandle(handle)) {
      clearNativeOverride();
      return;
    }

    final kind = switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.bottomRight =>
        'nwse',
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft =>
        'nesw',
      _ => null,
    };
    if (kind == null) {
      clearNativeOverride();
      return;
    }

    if (_activeMacosCursorKind == kind) {
      return;
    }

    _activeMacosCursorKind = kind;
    _channel.invokeMethod<void>('setCursor', kind);
  }

  static void clearNativeOverride() {
    if (_activeMacosCursorKind == null) {
      return;
    }

    _activeMacosCursorKind = null;
    _channel.invokeMethod<void>('setCursor', 'default');
  }
}
