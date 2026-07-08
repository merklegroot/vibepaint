import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/image_transforms.dart';

void main() {
  test('flipPointHorizontally mirrors across axis', () {
    expect(flipPointHorizontally(const Offset(10, 5), 50), const Offset(90, 5));
  });

  test('rotateAround rotates 90 degrees clockwise', () {
    const center = Offset(50, 50);
    final rotated = rotateAround(const Offset(80, 50), center, -3.141592653589793 / 2);
    expect(rotated.dx, closeTo(50, 0.001));
    expect(rotated.dy, closeTo(20, 0.001));
  });

  test('scaleAround scales from origin', () {
    final scaled = scaleAround(const Offset(10, 20), Offset.zero, 2, 3);
    expect(scaled, const Offset(20, 60));
  });

  test('documentSizeFromCropRect uses normalized width and height', () {
    const rect = Rect.fromLTRB(20, 30, 120, 180);
    expect(
      documentSizeFromCropRect(rect),
      const Size(100, 150),
    );
  });

  test('clipStrokeToSelection keeps interior freehand points', () {
    final selection = CanvasSelection.fromRect(
      SelectionShape.rectangle,
      const Rect.fromLTWH(0, 0, 100, 100),
    );
    final stroke = Stroke(
      color: Colors.red,
      brushSize: 4,
      points: const [
        Offset(10, 10),
        Offset(50, 50),
        Offset(150, 150),
      ],
    );

    final clipped = clipStrokeToSelection(stroke, selection);

    expect(clipped, isNotNull);
    expect(clipped!.points.length, 2);
  });
}
