import 'dart:math';
import 'dart:ui';

import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/stroke.dart';

Rect strokeBounds(Stroke stroke) {
  if (stroke.shape == StrokeShape.raster) {
    return stroke.rasterBounds ?? Rect.zero;
  }

  if (stroke.points.isEmpty) {
    return Rect.zero;
  }

  switch (stroke.shape) {
    case StrokeShape.line:
      if (stroke.points.length >= 2) {
        return Rect.fromPoints(stroke.points[0], stroke.points[1])
            .inflate(stroke.brushSize / 2);
      }
      break;
    case StrokeShape.rectangle:
    case StrokeShape.ellipse:
      if (stroke.points.length >= 2) {
        return Rect.fromPoints(stroke.points[0], stroke.points[1])
            .inflate(stroke.brushSize / 2);
      }
      break;
    case StrokeShape.freehand:
      break;
    case StrokeShape.raster:
      break;
  }

  var minX = stroke.points.first.dx;
  var maxX = minX;
  var minY = stroke.points.first.dy;
  var maxY = minY;

  for (final point in stroke.points) {
    minX = min(minX, point.dx);
    maxX = max(maxX, point.dx);
    minY = min(minY, point.dy);
    maxY = max(maxY, point.dy);
  }

  final half = stroke.brushSize / 2;
  return Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
}

bool strokeIntersectsSelection(CanvasSelection selection, Stroke stroke) {
  for (final point in stroke.points) {
    if (selection.contains(point)) {
      return true;
    }
  }

  return selection.bounds.overlaps(strokeBounds(stroke));
}

Stroke translateStroke(Stroke stroke, Offset delta) {
  return stroke.copyWith(
    points: [
      for (final point in stroke.points) point + delta,
    ],
    rasterBounds: stroke.rasterBounds?.shift(delta),
  );
}

List<Stroke> translateSelectedStrokes(
  Iterable<Stroke> strokes,
  CanvasSelection selection,
  Offset delta,
) {
  return [
    for (final stroke in strokes)
      if (strokeIntersectsSelection(selection, stroke))
        translateStroke(stroke, delta)
      else
        stroke,
  ];
}
