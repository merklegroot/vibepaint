import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/selection_handles.dart';

void main() {
  const bounds = Rect.fromLTWH(100, 100, 200, 100);
  const canvasBounds = Rect.fromLTWH(0, 0, 800, 600);

  test('hitTestSelectionHandle finds corner handle', () {
    expect(
      hitTestSelectionHandle(bounds.topLeft, bounds),
      SelectionResizeHandle.topLeft,
    );
    expect(
      hitTestSelectionHandle(bounds.bottomRight, bounds),
      SelectionResizeHandle.bottomRight,
    );
    expect(hitTestSelectionHandle(const Offset(50, 50), bounds), isNull);
  });

  test('hitTestSelectionHandle prefers corners over edges', () {
    const smallBounds = Rect.fromLTWH(100, 100, 20, 20);

    expect(
      hitTestSelectionHandle(smallBounds.bottomRight, smallBounds),
      SelectionResizeHandle.bottomRight,
    );
    expect(
      hitTestSelectionHandle(smallBounds.topRight, smallBounds),
      SelectionResizeHandle.topRight,
    );
  });

  test('resizeSelectionBounds grows from bottom-right handle', () {
    final resized = resizeSelectionBounds(
      original: bounds,
      handle: SelectionResizeHandle.bottomRight,
      current: const Offset(350, 250),
      canvasBounds: canvasBounds,
    );

    expect(resized, const Rect.fromLTWH(100, 100, 250, 150));
  });

  test('cursorForSelectionHandle maps corners to diagonal resize cursors', () {
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.topLeft),
      SystemMouseCursors.resizeUpLeftDownRight,
    );
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.bottomRight),
      SystemMouseCursors.resizeUpLeftDownRight,
    );
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.topRight),
      SystemMouseCursors.resizeUpRightDownLeft,
    );
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.bottomLeft),
      SystemMouseCursors.resizeUpRightDownLeft,
    );
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.centerLeft),
      SystemMouseCursors.resizeLeftRight,
    );
    expect(
      cursorForSelectionHandle(SelectionResizeHandle.topCenter),
      SystemMouseCursors.resizeUpDown,
    );
  });
}
