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

  test('clipped line end stops at canvas edge', () {
    const bounds = Rect.fromLTWH(0, 0, 1024, 576);
    final end = clippedLineEnd(
      start: const Offset(500, 300),
      end: const Offset(1100, 300),
      bounds: bounds,
    );

    expect(end, isNotNull);
    expect(end!.dx, closeTo(1024, 0.01));
    expect(end.dy, closeTo(300, 0.01));
  });

  test('clipped rectangle corners stay inside canvas', () {
    final corners = clippedRectangleCorners(
      start: const Offset(500, 300),
      end: const Offset(1100, 500),
      bounds: bounds,
    );

    expect(corners, isNotNull);
    expect(corners!.topLeft, const Offset(500, 300));
    expect(corners.bottomRight.dx, closeTo(1024, 0.01));
    expect(corners.bottomRight.dy, closeTo(500, 0.01));
  });

  test('clipped rectangle rejects zero-area drag', () {
    final corners = clippedRectangleCorners(
      start: const Offset(500, 300),
      end: const Offset(500, 300),
      bounds: bounds,
    );

    expect(corners, isNull);
  });

  test('constrained line end snaps to horizontal', () {
    final end = constrainedLineEnd(
      start: const Offset(100, 100),
      end: const Offset(180, 130),
    );

    expect(end.dy, closeTo(100, 0.01));
    expect(end.dx, greaterThan(100));
  });

  test('shape bounding rect constrains to square', () {
    final rect = shapeBoundingRect(
      start: const Offset(100, 100),
      end: const Offset(220, 140),
      constrainSquare: true,
    );

    expect(rect.width, closeTo(120, 0.01));
    expect(rect.height, closeTo(120, 0.01));
    expect(rect.bottomRight, const Offset(220, 220));
  });

  test('shape bounding rect draws from center with alt', () {
    final rect = shapeBoundingRect(
      start: const Offset(200, 200),
      end: const Offset(260, 240),
      fromCenter: true,
    );

    expect(rect.center, const Offset(200, 200));
    expect(rect.width, closeTo(120, 0.01));
    expect(rect.height, closeTo(80, 0.01));
  });

  test('clipped shape bounds combine shift and alt modifiers', () {
    final corners = clippedShapeBounds(
      start: const Offset(300, 300),
      end: const Offset(420, 360),
      bounds: bounds,
      constrainSquare: true,
      fromCenter: true,
    );

    expect(corners, isNotNull);
    final rect = Rect.fromPoints(corners!.topLeft, corners.bottomRight);
    expect(rect.center.dx, closeTo(300, 0.01));
    expect(rect.center.dy, closeTo(300, 0.01));
    expect(rect.width, closeTo(rect.height, 0.01));
  });
}
