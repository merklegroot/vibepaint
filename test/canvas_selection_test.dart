import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/canvas_selection.dart';

void main() {
  test('rectangle selection contains interior points', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(10, 10, 100, 50),
    );

    expect(selection.contains(const Offset(50, 30)), isTrue);
    expect(selection.contains(const Offset(5, 30)), isFalse);
  });

  test('ellipse selection contains interior points', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.ellipse,
      const Rect.fromLTWH(0, 0, 100, 100),
    );

    expect(selection.contains(const Offset(50, 50)), isTrue);
    expect(selection.contains(const Offset(5, 5)), isFalse);
  });

  test('invert selection flips inside and outside', () {
    const canvasSize = Size(100, 100);
    final inner = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(25, 25, 50, 50),
    );

    final inverted = inner.inverted(canvasSize);

    expect(inner.contains(const Offset(50, 50)), isTrue);
    expect(inverted.contains(const Offset(50, 50)), isFalse);
    expect(inverted.contains(const Offset(5, 5)), isTrue);
  });
}
