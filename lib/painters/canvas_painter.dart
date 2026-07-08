import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart' show Stroke, StrokeShape;

class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.layers,
    required this.activeLayerIndex,
    this.currentStroke,
    this.backgroundImage,
  });

  final List<PaintLayer> layers;
  final int activeLayerIndex;
  final Stroke? currentStroke;
  final ui.Image? backgroundImage;

  static void paintCanvas({
    required Canvas canvas,
    required Size size,
    required List<PaintLayer> layers,
    required int activeLayerIndex,
    Stroke? currentStroke,
    ui.Image? backgroundImage,
  }) {
    final bounds = Offset.zero & size;

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
    } else {
      canvas.drawRect(bounds, Paint()..color = Colors.white);
    }

    for (var i = 0; i < layers.length; i++) {
      _paintLayer(
        canvas: canvas,
        bounds: bounds,
        layer: layers[i],
        currentStroke: i == activeLayerIndex ? currentStroke : null,
      );
    }
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
      _paintStroke(canvas, stroke);
    }

    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke);
    }

    canvas.restore();
  }

  static void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    final blendMode =
        stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
    final fill = Paint()
      ..color = stroke.isEraser ? Colors.transparent : stroke.color
      ..style = PaintingStyle.fill
      ..blendMode = blendMode;
    final line = Paint()
      ..color = stroke.isEraser ? Colors.transparent : stroke.color
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
      case StrokeShape.freehand:
        break;
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
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (oldDelegate.backgroundImage != backgroundImage) {
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
