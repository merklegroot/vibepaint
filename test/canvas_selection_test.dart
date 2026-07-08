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
    expect(inverted.canReshape, isFalse);
  });

  test('withShape converts rectangle to ellipse', () {
    final rect = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(10, 10, 80, 60),
    );

    final ellipse = rect.withShape(SelectionShape.ellipse);

    expect(ellipse.shape, SelectionShape.ellipse);
    expect(ellipse.bounds, rect.bounds);
    expect(ellipse.canReshape, isTrue);
    expect(ellipse.contains(const Offset(50, 40)), isTrue);
  });

  test('lasso selection contains interior points when closed', () {
    final selection = CanvasSelection.fromPoints(const [
      Offset(10, 10),
      Offset(90, 10),
      Offset(90, 90),
      Offset(10, 90),
    ]);

    expect(selection.shape, SelectionShape.lasso);
    expect(selection.isEmpty, isFalse);
    expect(selection.canReshape, isFalse);
    expect(selection.contains(const Offset(50, 50)), isTrue);
    expect(selection.contains(const Offset(5, 5)), isFalse);
  });

  test('lasso selection with too few points is empty', () {
    final selection = CanvasSelection.fromPoints(const [
      Offset(10, 10),
      Offset(20, 20),
    ]);

    expect(selection.isEmpty, isTrue);
  });

  test('zero area selection is empty', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      Rect.fromPoints(const Offset(10, 10), const Offset(10, 10)),
    );

    expect(selection.isEmpty, isTrue);
    expect(selection.canReshape, isFalse);
  });

  test('withBounds updates simple selection', () {
    final original = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(10, 10, 50, 50),
    );

    final resized = original.withBounds(
      const Rect.fromLTWH(20, 20, 60, 40),
    );

    expect(resized.bounds, const Rect.fromLTWH(20, 20, 60, 40));
    expect(resized.contains(const Offset(25, 25)), isTrue);
    expect(resized.contains(const Offset(10, 10)), isFalse);
  });
}
