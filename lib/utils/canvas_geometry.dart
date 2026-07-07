import 'dart:math';
import 'dart:ui';

bool isInsideCanvas(Offset position, double width, double height) {
  return position.dx >= 0 &&
      position.dy >= 0 &&
      position.dx <= width &&
      position.dy <= height;
}

/// Where [from]-[to] first crosses [bounds] along the segment (0 < t <= 1).
Offset? segmentBoundaryCrossing(Offset from, Offset to, Rect bounds) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  double? bestT;

  void consider(double t, double x, double y) {
    if (t <= 0 || t > 1) {
      return;
    }
    if (x < bounds.left || x > bounds.right || y < bounds.top || y > bounds.bottom) {
      return;
    }
    if (bestT == null || t < bestT!) {
      bestT = t;
    }
  }

  if (dx.abs() > 1e-9) {
    for (final x in [bounds.left, bounds.right]) {
      final t = (x - from.dx) / dx;
      consider(t, x, from.dy + t * dy);
    }
  }

  if (dy.abs() > 1e-9) {
    for (final y in [bounds.top, bounds.bottom]) {
      final t = (y - from.dy) / dy;
      consider(t, from.dx + t * dx, y);
    }
  }

  if (bestT == null) {
    return null;
  }

  return Offset(from.dx + bestT! * dx, from.dy + bestT! * dy);
}

/// Sample points along a segment so fast strokes stay continuous.
List<Offset> interpolateSegment(
  Offset from,
  Offset to, {
  required double maxStep,
}) {
  final delta = to - from;
  final distance = delta.distance;
  if (distance <= maxStep) {
    return [to];
  }

  final steps = distance.ceil() ~/ maxStep;
  final step = 1 / steps;
  final points = <Offset>[];

  for (var i = 1; i <= steps; i++) {
    final t = step * i;
    points.add(Offset(from.dx + delta.dx * t, from.dy + delta.dy * t));
  }

  return points;
}

List<Offset> strokeExtensionPoints({
  required Offset from,
  required Offset to,
  required Rect bounds,
  required double maxStep,
}) {
  final fromInside = bounds.contains(from);
  final toInside = bounds.contains(to);

  if (fromInside && toInside) {
    return interpolateSegment(from, to, maxStep: maxStep);
  }

  if (fromInside && !toInside) {
    final crossing = segmentBoundaryCrossing(from, to, bounds);
    if (crossing == null) {
      return const [];
    }
    return interpolateSegment(from, crossing, maxStep: maxStep);
  }

  return const [];
}

/// Points for a stroke re-entering the canvas from outside.
List<Offset> strokeReentryPoints({
  required Offset from,
  required Offset to,
  required Rect bounds,
  required double maxStep,
}) {
  if (!bounds.contains(to)) {
    return const [];
  }

  if (bounds.contains(from)) {
    return interpolateSegment(from, to, maxStep: maxStep);
  }

  final entry = segmentBoundaryCrossing(from, to, bounds);
  if (entry == null) {
    return [to];
  }

  return [entry, ...interpolateSegment(entry, to, maxStep: maxStep)];
}

/// Clips [end] to the canvas edge along the segment from [start].
Offset? clippedLineEnd({
  required Offset start,
  required Offset end,
  required Rect bounds,
  bool constrainAngle = false,
}) {
  final target = constrainAngle
      ? constrainedLineEnd(start: start, end: end)
      : end;

  if (bounds.contains(target)) {
    return target;
  }

  if (!bounds.contains(start)) {
    return null;
  }

  return segmentBoundaryCrossing(start, target, bounds) ?? target;
}

/// Snaps a line segment to the nearest 45° angle while keeping its length.
Offset constrainedLineEnd({
  required Offset start,
  required Offset end,
}) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final distance = sqrt(dx * dx + dy * dy);
  if (distance < 1e-9) {
    return end;
  }

  const quarterTurn = pi / 4;
  final angle = atan2(dy, dx);
  final snapped = (angle / quarterTurn).round() * quarterTurn;
  return Offset(
    start.dx + cos(snapped) * distance,
    start.dy + sin(snapped) * distance,
  );
}

/// Bounding box for rectangle and ellipse drags.
Rect shapeBoundingRect({
  required Offset start,
  required Offset end,
  bool constrainSquare = false,
  bool fromCenter = false,
}) {
  var dx = end.dx - start.dx;
  var dy = end.dy - start.dy;

  if (constrainSquare) {
    final size = max(dx.abs(), dy.abs());
    dx = dx >= 0 ? size : -size;
    dy = dy >= 0 ? size : -size;
  }

  if (fromCenter) {
    return Rect.fromCenter(
      center: start,
      width: dx.abs() * 2,
      height: dy.abs() * 2,
    );
  }

  return Rect.fromPoints(start, Offset(start.dx + dx, start.dy + dy));
}

/// Opposite corners of a bounding-box shape clipped to [bounds].
({Offset topLeft, Offset bottomRight})? clippedShapeBounds({
  required Offset start,
  required Offset end,
  required Rect bounds,
  bool constrainSquare = false,
  bool fromCenter = false,
}) {
  if (!bounds.contains(start)) {
    return null;
  }

  final rect = shapeBoundingRect(
    start: start,
    end: end,
    constrainSquare: constrainSquare,
    fromCenter: fromCenter,
  ).intersect(bounds);
  if (rect.width <= 0 || rect.height <= 0) {
    return null;
  }

  return (topLeft: rect.topLeft, bottomRight: rect.bottomRight);
}

/// Opposite corners of a rectangle clipped to [bounds].
({Offset topLeft, Offset bottomRight})? clippedRectangleCorners({
  required Offset start,
  required Offset end,
  required Rect bounds,
}) {
  return clippedShapeBounds(start: start, end: end, bounds: bounds);
}
