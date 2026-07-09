import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/selection_geometry.dart';

/// Anchor used when expanding the canvas without scaling content.
enum CanvasAnchor {
  topLeft,
  center,
}

Rect? contentBounds({
  required Iterable<PaintLayer> layers,
  required Size canvasSize,
  bool includeBackground = true,
}) {
  Rect? bounds;

  for (final layer in layers) {
    if (!layer.visible) {
      continue;
    }
    for (final stroke in layer.history.strokes) {
      final strokeRect = strokeBounds(stroke);
      if (strokeRect.isEmpty) {
        continue;
      }
      bounds = bounds == null
          ? strokeRect
          : bounds.expandToInclude(strokeRect);
    }
  }

  if (includeBackground && bounds == null) {
    return Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
  }

  return bounds;
}

Offset flipPointHorizontally(Offset point, double axisX) {
  return Offset((2 * axisX) - point.dx, point.dy);
}

Offset flipPointVertically(Offset point, double axisY) {
  return Offset(point.dx, (2 * axisY) - point.dy);
}

Offset rotateAround(Offset point, Offset center, double radians) {
  final delta = point - center;
  final cosR = cos(radians);
  final sinR = sin(radians);
  return Offset(
    center.dx + (delta.dx * cosR) - (delta.dy * sinR),
    center.dy + (delta.dx * sinR) + (delta.dy * cosR),
  );
}

Offset scaleAround(
  Offset point,
  Offset origin,
  double scaleX,
  double scaleY,
) {
  final delta = point - origin;
  return origin + Offset(delta.dx * scaleX, delta.dy * scaleY);
}

double scaleBrushSize(double brushSize, double scaleX, double scaleY) {
  return brushSize * sqrt(scaleX * scaleY);
}

Stroke transformStroke(
  Stroke stroke,
  Offset Function(Offset point) transformPoint, {
  double? brushSize,
}) {
  if (stroke.shape == StrokeShape.raster) {
    final bounds = stroke.rasterBounds;
    if (bounds == null) {
      return stroke;
    }

    return stroke.copyWith(
      points: [transformPoint(bounds.topLeft)],
      rasterBounds: Rect.fromPoints(
        transformPoint(bounds.topLeft),
        transformPoint(bounds.bottomRight),
      ),
      brushSize: brushSize ?? stroke.brushSize,
    );
  }

  if (stroke.shape == StrokeShape.text) {
    final textRun = stroke.textRun;
    if (textRun == null) {
      return stroke;
    }
    final nextFontSize = brushSize ?? textRun.fontSize;
    return stroke.copyWith(
      points: [transformPoint(textRun.position)],
      brushSize: nextFontSize,
      textRun: textRun.copyWith(
        position: transformPoint(textRun.position),
        fontSize: nextFontSize,
      ),
    );
  }

  return stroke.copyWith(
    points: [for (final point in stroke.points) transformPoint(point)],
    brushSize: brushSize ?? stroke.brushSize,
  );
}

Stroke? clipStrokeToRect(Stroke stroke, Rect rect) {
  switch (stroke.shape) {
    case StrokeShape.raster:
      final bounds = stroke.rasterBounds;
      if (bounds == null || !bounds.overlaps(rect)) {
        return null;
      }
      return stroke;
    case StrokeShape.text:
      final bounds = stroke.textRun?.bounds();
      if (bounds == null || !bounds.overlaps(rect)) {
        return null;
      }
      return stroke;
    case StrokeShape.line:
    case StrokeShape.rectangle:
    case StrokeShape.ellipse:
    case StrokeShape.gradient:
      if (stroke.points.length < 2) {
        return null;
      }
      final bounds = strokeBounds(stroke);
      if (!bounds.overlaps(rect)) {
        return null;
      }
      return stroke;
    case StrokeShape.freehand:
      final clippedPoints = [
        for (final point in stroke.points)
          if (rect.contains(point)) point,
      ];
      if (clippedPoints.length < 2) {
        return null;
      }
      return stroke.copyWith(points: clippedPoints);
  }
}

Size documentSizeFromCropRect(Rect rect) {
  final normalized = Rect.fromPoints(rect.topLeft, rect.bottomRight);
  return Size(normalized.width, normalized.height);
}

Offset canvasResizeOffset({
  required Size currentSize,
  required Size newSize,
  CanvasAnchor anchor = CanvasAnchor.center,
}) {
  if (anchor == CanvasAnchor.topLeft) {
    return Offset.zero;
  }

  return Offset(
    (newSize.width - currentSize.width) / 2,
    (newSize.height - currentSize.height) / 2,
  );
}

Stroke? clipStrokeToSelection(Stroke stroke, CanvasSelection selection) {
  switch (stroke.shape) {
    case StrokeShape.raster:
      if (!strokeIntersectsSelection(selection, stroke)) {
        return null;
      }
      return stroke;
    case StrokeShape.text:
      if (!strokeIntersectsSelection(selection, stroke)) {
        return null;
      }
      return stroke;
    case StrokeShape.line:
    case StrokeShape.rectangle:
    case StrokeShape.ellipse:
    case StrokeShape.gradient:
      if (stroke.points.length < 2) {
        return null;
      }
      if (!strokeIntersectsSelection(selection, stroke)) {
        return null;
      }
      return stroke;
    case StrokeShape.freehand:
      final clippedPoints = [
        for (final point in stroke.points)
          if (selection.contains(point)) point,
      ];
      if (clippedPoints.length < 2) {
        return null;
      }
      return stroke.copyWith(points: clippedPoints);
  }
}

CanvasSelection translateSelection(CanvasSelection selection, Offset offset) {
  final matrix = Matrix4.translationValues(offset.dx, offset.dy, 0);
  return CanvasSelection(
    shape: selection.shape,
    path: selection.path.transform(matrix.storage),
    bounds: selection.bounds.shift(offset),
    isSimple: selection.isSimple,
  );
}
