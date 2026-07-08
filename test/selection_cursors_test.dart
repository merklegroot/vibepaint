import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/selection_cursors.dart';
import 'package:vibepaint/utils/selection_handles.dart';

void main() {
  test('mouseCursorFor uses native diagonal cursors on macOS corners', () {
    final cursor = SelectionCursors.mouseCursorFor(
      SelectionResizeHandle.topLeft,
    );

    if (!kIsWeb && Platform.isMacOS) {
      expect(cursor, MouseCursor.defer);
    } else {
      expect(cursor, SystemMouseCursors.resizeUpLeftDownRight);
    }
  });

  test('mouseCursorFor returns axis resize cursors for edge handles', () {
    expect(
      SelectionCursors.mouseCursorFor(SelectionResizeHandle.topCenter),
      SystemMouseCursors.resizeUpDown,
    );
    expect(
      SelectionCursors.mouseCursorFor(SelectionResizeHandle.centerLeft),
      SystemMouseCursors.resizeLeftRight,
    );
  });
}
