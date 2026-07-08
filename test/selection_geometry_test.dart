import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/selection_geometry.dart';

void main() {
  test('strokeIntersectsSelection detects overlapping strokes', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(0, 0, 50, 50),
    );
    final stroke = Stroke(
      color: Colors.red,
      brushSize: 4,
      points: const [Offset(10, 10), Offset(80, 80)],
    );

    expect(strokeIntersectsSelection(selection, stroke), isTrue);
  });

  test('translateSelectedStrokes moves only selected strokes', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(0, 0, 50, 50),
    );
    final strokes = [
      Stroke(color: Colors.red, brushSize: 4, points: const [Offset(10, 10)]),
      Stroke(color: Colors.blue, brushSize: 4, points: const [Offset(80, 80)]),
    ];

    final moved = translateSelectedStrokes(
      strokes,
      selection,
      const Offset(5, 5),
    );

    expect(moved[0].points.first, const Offset(15, 15));
    expect(moved[1].points.first, const Offset(80, 80));
  });
}
