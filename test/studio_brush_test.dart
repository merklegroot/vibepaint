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

  test('studioBrushPressureFromVelocity tapers fast strokes', () {
    final slow = studioBrushPressureFromVelocity(40, 12);
    final fast = studioBrushPressureFromVelocity(800, 12);

    expect(slow, greaterThan(fast));
    expect(fast, lessThan(0.75));
  });

  test('studioBrushPressureRamped stays soft until the pointer moves', () {
    final resting = studioBrushPressureRamped(
      pressure: 0.8,
      travelFromStart: 0,
      brushSize: 12,
    );
    final moving = studioBrushPressureRamped(
      pressure: 0.8,
      travelFromStart: 12 * studioBrushStartRampFactor,
      brushSize: 12,
    );

    expect(resting, studioBrushInitialTouchPressure);
    expect(moving, 0.8);
  });

  test('studioBrushPressureFromVelocity eases off at a full stop', () {
    final stopped = studioBrushPressureFromVelocity(0, 12);
    final slowDrift = studioBrushPressureFromVelocity(30, 12);

    expect(stopped, lessThan(slowDrift));
    expect(stopped, lessThan(0.65));
  });

  test('studioBrushPressuresForPoints tapers long interpolated steps', () {
    final pressures = studioBrushPressuresForPoints(
      previousPoint: Offset.zero,
      points: const [Offset(20, 0), Offset(40, 0)],
      endPressure: 0.9,
      brushSize: 12,
    );

    expect(pressures.length, 2);
    expect(pressures.first, lessThan(0.9));
    expect(pressures.last, lessThanOrEqualTo(pressures.first));
  });
}
