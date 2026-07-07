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
}) {
  if (bounds.contains(end)) {
    return end;
  }

  if (!bounds.contains(start)) {
    return null;
  }

  return segmentBoundaryCrossing(start, end, bounds) ?? end;
}

/// Opposite corners of a rectangle clipped to [bounds].
({Offset topLeft, Offset bottomRight})? clippedRectangleCorners({
  required Offset start,
  required Offset end,
  required Rect bounds,
}) {
  if (!bounds.contains(start)) {
    return null;
  }

  final rect = Rect.fromPoints(start, end).intersect(bounds);
  if (rect.width <= 0 || rect.height <= 0) {
    return null;
  }

  return (topLeft: rect.topLeft, bottomRight: rect.bottomRight);
}
