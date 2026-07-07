import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 1024, 576);

  test('finds boundary crossing when pointer jumps outside', () {
    final exit = segmentBoundaryCrossing(
      const Offset(900, 200),
      const Offset(1100, 200),
      bounds,
    );

    expect(exit, isNotNull);
    expect(exit!.dx, closeTo(1024, 0.01));
    expect(exit.dy, closeTo(200, 0.01));
  });

  test('stroke extension reaches the canvas edge on fast exit', () {
    final points = strokeExtensionPoints(
      from: const Offset(900, 200),
      to: const Offset(1100, 200),
      bounds: bounds,
      maxStep: 3,
    );

    expect(points, isNotEmpty);
    expect(points.last.dx, closeTo(1024, 0.01));
  });

  test('stroke reentry reaches the canvas edge on fast return', () {
    final points = strokeReentryPoints(
      from: const Offset(1100, 200),
      to: const Offset(900, 200),
      bounds: bounds,
      maxStep: 3,
    );

    expect(points, isNotEmpty);
    expect(points.first.dx, closeTo(1024, 0.01));
    expect(points.last.dx, closeTo(900, 0.01));
  });
}
