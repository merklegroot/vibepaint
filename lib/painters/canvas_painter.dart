import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart' show Stroke, StrokeShape;
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/studio_brush.dart';

class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.layers,
    required this.activeLayerIndex,
    this.currentStroke,
    this.backgroundImage,
    this.backgroundColor = defaultCanvasBackground,
    this.previewRotation = 0,
  });

  final List<PaintLayer> layers;
  final int activeLayerIndex;
  final Stroke? currentStroke;
  final ui.Image? backgroundImage;
  final Color backgroundColor;
  final double previewRotation;

  static void paintCanvas({
    required Canvas canvas,
    required Size size,
    required List<PaintLayer> layers,
    required int activeLayerIndex,
    Stroke? currentStroke,
    ui.Image? backgroundImage,
    Color backgroundColor = defaultCanvasBackground,
    double previewRotation = 0,
  }) {
    final bounds = Offset.zero & size;

    canvas.save();
    if (previewRotation != 0) {
      final center = bounds.center;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(previewRotation);
      canvas.translate(-center.dx, -center.dy);
    }

    _paintDocumentBackground(
      canvas: canvas,
      bounds: bounds,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
    );

    for (var i = 0; i < layers.length; i++) {
      _paintLayer(
        canvas: canvas,
        bounds: bounds,
        layer: layers[i],
        currentStroke: i == activeLayerIndex ? currentStroke : null,
      );
    }

    canvas.restore();
  }

  static void _paintDocumentBackground({
    required Canvas canvas,
    required Rect bounds,
    required Color backgroundColor,
    ui.Image? backgroundImage,
  }) {
    if (isTransparentCanvasBackground(backgroundColor) &&
        backgroundImage == null) {
      _paintCheckerboard(canvas, bounds);
      return;
    }

    if (!isTransparentCanvasBackground(backgroundColor)) {
      canvas.drawRect(bounds, Paint()..color = backgroundColor);
    } else {
      _paintCheckerboard(canvas, bounds);
    }

    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble(),
        ),
        bounds,
        Paint(),
      );
    }
  }

  static void _paintCheckerboard(Canvas canvas, Rect bounds) {
    const cellSize = 10.0;
    const light = Color(0xFFCCCCCC);
    const dark = Color(0xFF999999);

    canvas.save();
    canvas.clipRect(bounds);

    for (var y = bounds.top; y < bounds.bottom; y += cellSize) {
      for (var x = bounds.left; x < bounds.right; x += cellSize) {
        final row = ((y - bounds.top) / cellSize).floor();
        final col = ((x - bounds.left) / cellSize).floor();
        final color = (row + col).isEven ? light : dark;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          Paint()..color = color,
        );
      }
    }

    canvas.restore();
  }

  static void _paintLayer({
    required Canvas canvas,
    required Rect bounds,
    required PaintLayer layer,
    Stroke? currentStroke,
  }) {
    if (!layer.visible) {
      return;
    }

    canvas.saveLayer(
      bounds,
      Paint()
        ..blendMode = layer.blendMode.paintBlendMode
        ..color = Color.fromRGBO(255, 255, 255, layer.opacity),
    );

    for (final stroke in layer.history.strokes) {
      paintStroke(canvas, stroke, canvasBounds: bounds);
    }

    if (currentStroke != null) {
      paintStroke(canvas, currentStroke, canvasBounds: bounds);
    }

    canvas.restore();
  }

  static void paintStroke(
    Canvas canvas,
    Stroke stroke, {
    Rect? canvasBounds,
  }) {
    if (stroke.isEmpty) {
      return;
    }

    if (stroke.shape == StrokeShape.raster) {
      final image = stroke.rasterImage;
      final bounds = stroke.rasterBounds;
      if (image == null || bounds == null) {
        return;
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        bounds,
        Paint()..blendMode = BlendMode.srcOver,
      );
      return;
    }

    if (stroke.shape == StrokeShape.text) {
      final textRun = stroke.textRun;
      if (textRun == null || textRun.isEmpty) {
        return;
      }
      final painter = textRun.createPainter();
      try {
        painter.paint(canvas, textRun.position);
      } finally {
        painter.dispose();
      }
      return;
    }

    if (stroke.points.isEmpty) {
      return;
    }

    final blendMode =
        stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
    final strokeColor = stroke.isEraser
        ? Colors.transparent
        : stroke.color.withValues(
            alpha: (stroke.color.a * stroke.brushOpacity).clamp(0, 1),
          );
    final fill = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill
      ..blendMode = blendMode;
    final line = Paint()
      ..color = strokeColor
      ..strokeWidth = stroke.brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = blendMode;

    switch (stroke.shape) {
      case StrokeShape.line:
        if (stroke.points.length >= 2) {
          canvas.drawLine(stroke.points[0], stroke.points[1], line);
        }
        return;
      case StrokeShape.rectangle:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
          _paintBoundedShape(
            canvas: canvas,
            draw: (paint) => canvas.drawRect(rect, paint),
            fill: fill,
            line: line,
            style: stroke.style,
          );
        }
        return;
      case StrokeShape.ellipse:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
          _paintBoundedShape(
            canvas: canvas,
            draw: (paint) => canvas.drawOval(rect, paint),
            fill: fill,
            line: line,
            style: stroke.style,
          );
        }
        return;
      case StrokeShape.gradient:
        if (stroke.points.length >= 2 && stroke.secondaryColor != null) {
          final bounds = canvasBounds ??
              Rect.fromPoints(stroke.points[0], stroke.points[1]);
          final gradientPaint = Paint()
            ..shader = ui.Gradient.linear(
              stroke.points[0],
              stroke.points[1],
              [stroke.color, stroke.secondaryColor!],
            )
            ..blendMode = blendMode;
          canvas.drawRect(bounds, gradientPaint);
        }
        return;
      case StrokeShape.freehand:
        if (stroke.isStudioBrush) {
          _paintStudioBrushStroke(canvas, stroke);
          return;
        }
        if (stroke.isPencil) {
          _paintPencilStroke(canvas, stroke, fill, line);
          return;
        }
        break;
      case StrokeShape.raster:
      case StrokeShape.text:
        return;
    }

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.brushSize / 2, fill);
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], line);
    }

    canvas.drawCircle(stroke.points.last, stroke.brushSize / 2, fill);
  }

  static void _paintStudioBrushStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    final baseAlpha =
        (stroke.color.a * stroke.brushOpacity).clamp(0.0, 1.0).toDouble();
    final blendMode =
        stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

    void stampAt(Offset point, double pressure) {
      final radius = studioBrushRadius(stroke.brushSize, pressure);
      if (radius <= 0) {
        return;
      }

      final alpha = studioBrushOpacity(baseAlpha, pressure).toDouble();
      final color = stroke.isEraser
          ? Colors.transparent
          : stroke.color.withValues(alpha: alpha);

      final soft = Paint()
        ..color = color
        ..blendMode = blendMode
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
      canvas.drawCircle(point, radius, soft);

      final core = Paint()
        ..color = color.withValues(
          alpha: (alpha * 0.65).clamp(0.04, 1.0).toDouble(),
        )
        ..blendMode = blendMode;
      canvas.drawCircle(point, radius * 0.55, core);
    }

    if (stroke.points.length == 1) {
      final pressure =
          stroke.pressures.isNotEmpty ? stroke.pressures.first : 1.0;
      stampAt(stroke.points.first, pressure);
      return;
    }

    final maxStep = stroke.brushSize * studioBrushSpacingFactor;
    for (var i = 0; i < stroke.points.length; i++) {
      final pressure =
          i < stroke.pressures.length ? stroke.pressures[i] : 1.0;
      stampAt(stroke.points[i], pressure);

      if (i == stroke.points.length - 1) {
        continue;
      }

      final from = stroke.points[i];
      final to = stroke.points[i + 1];
      final nextPressure =
          i + 1 < stroke.pressures.length ? stroke.pressures[i + 1] : pressure;
      final steps = studioBrushSegmentPoints(
        from: from,
        to: to,
        maxStep: maxStep,
      );

      for (var j = 0; j < steps.length; j++) {
        final t = steps.length == 1 ? 1 : (j + 1) / steps.length;
        final interpolatedPressure =
            pressure + (nextPressure - pressure) * t;
        stampAt(steps[j], interpolatedPressure);
      }
    }
  }

  static void _paintPencilStroke(
    Canvas canvas,
    Stroke stroke,
    Paint fill,
    Paint line,
  ) {
    line.strokeCap = StrokeCap.square;
    line.strokeJoin = StrokeJoin.miter;

    if (stroke.points.length == 1) {
      canvas.drawRect(
        Rect.fromCenter(
          center: stroke.points.first,
          width: stroke.brushSize,
          height: stroke.brushSize,
        ),
        fill,
      );
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], line);
    }
  }

  static void _paintBoundedShape({
    required Canvas canvas,
    required void Function(Paint paint) draw,
    required Paint fill,
    required Paint line,
    required ShapeStyle style,
  }) {
    if (style.drawsFill) {
      draw(fill);
    }
    if (style.drawsOutline) {
      draw(line);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintCanvas(
      canvas: canvas,
      size: size,
      layers: layers,
      activeLayerIndex: activeLayerIndex,
      currentStroke: currentStroke,
      backgroundImage: backgroundImage,
      backgroundColor: backgroundColor,
      previewRotation: previewRotation,
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (oldDelegate.previewRotation != previewRotation) {
      return true;
    }

    if (oldDelegate.backgroundImage != backgroundImage) {
      return true;
    }

    if (oldDelegate.backgroundColor != backgroundColor) {
      return true;
    }

    if (oldDelegate.activeLayerIndex != activeLayerIndex) {
      return true;
    }

    if (oldDelegate.layers.length != layers.length) {
      return true;
    }

    for (var i = 0; i < layers.length; i++) {
      final oldLayer = oldDelegate.layers[i];
      final newLayer = layers[i];
      if (oldLayer.visible != newLayer.visible) {
        return true;
      }
      if (oldLayer.opacity != newLayer.opacity) {
        return true;
      }
      if (oldLayer.blendMode != newLayer.blendMode) {
        return true;
      }
      if (oldLayer.history.strokes.length != newLayer.history.strokes.length) {
        return true;
      }
    }

    final oldCurrent = oldDelegate.currentStroke;
    final newCurrent = currentStroke;
    if (oldCurrent == null && newCurrent == null) {
      return false;
    }
    if (oldCurrent == null || newCurrent == null) {
      return true;
    }

    return oldCurrent.points.length != newCurrent.points.length;
  }
}
