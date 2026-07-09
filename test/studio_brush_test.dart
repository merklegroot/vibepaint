import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/studio_brush.dart';

void main() {
  test('normalizePointerPressure defaults mouse input to full pressure', () {
    expect(normalizePointerPressure(0), 1);
    expect(normalizePointerPressure(1), 1);
  });

  test('stabilizeStudioPoint eases toward the target', () {
    const anchor = Offset(0, 0);
    const target = Offset(100, 0);

    final eased = stabilizeStudioPoint(
      target,
      anchor,
      studioBrushResponsiveness,
    );

    expect(eased.dx, greaterThan(0));
    expect(eased.dx, lessThan(100));
  });

  test('studioBrushSegmentPoints subdivides long moves', () {
    final points = studioBrushSegmentPoints(
      from: Offset.zero,
      to: const Offset(10, 0),
      maxStep: 4,
    );

    expect(points.length, 3);
    expect(points.last, const Offset(10, 0));
  });
}
