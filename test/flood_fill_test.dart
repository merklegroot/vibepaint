import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/flood_fill.dart';

void main() {
  test('floodFillToleranceFromBrushSize maps brush size to threshold', () {
    expect(floodFillToleranceFromBrushSize(2), 0);
    expect(floodFillToleranceFromBrushSize(12), 25);
    expect(floodFillToleranceFromBrushSize(48), 115);
  });

  test('traceMaskContour follows a filled rectangle', () {
    const width = 6;
    const height = 6;
    final mask = Uint8List(width * height);

    for (var y = 1; y <= 4; y++) {
      for (var x = 1; x <= 4; x++) {
        mask[y * width + x] = 255;
      }
    }

    final contour = traceMaskContour(mask, width, height);
    expect(contour.length, greaterThanOrEqualTo(4));
    expect(contour.first, const Offset(1.5, 1.5));
  });

  test('boundsOfMask returns the filled region bounds', () {
    const width = 8;
    const height = 8;
    final mask = Uint8List(width * height);
    mask[3 * width + 2] = 255;
    mask[3 * width + 5] = 255;
    mask[6 * width + 5] = 255;

    final bounds = boundsOfMask(mask, width, height);
    expect(bounds, Rect.fromLTRB(2, 3, 6, 7));
  });
}
