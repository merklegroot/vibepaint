import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/text_run.dart';

enum StrokeShape {
  freehand,
  line,
  rectangle,
  ellipse,
  raster,
  text,
}

class Stroke {
  Stroke({
    required this.color,
    required this.brushSize,
    List<Offset>? points,
    this.shape = StrokeShape.freehand,
    this.style = ShapeStyle.outline,
    this.isEraser = false,
    this.isPencil = false,
    this.rasterImage,
    this.rasterBounds,
    this.textRun,
  }) : points = points ?? [];

  final Color color;
  final double brushSize;
  final List<Offset> points;
  final StrokeShape shape;
  final ShapeStyle style;
  final bool isEraser;
  final bool isPencil;
  final ui.Image? rasterImage;
  final Rect? rasterBounds;
  final TextRun? textRun;

  bool get isEmpty {
    if (shape == StrokeShape.raster) {
      return rasterImage == null || rasterBounds == null;
    }
    if (shape == StrokeShape.text) {
      return textRun == null || textRun!.isEmpty;
    }
    return points.isEmpty;
  }

  Stroke copyWith({
    Color? color,
    double? brushSize,
    List<Offset>? points,
    StrokeShape? shape,
    ShapeStyle? style,
    bool? isEraser,
    bool? isPencil,
    ui.Image? rasterImage,
    Rect? rasterBounds,
    TextRun? textRun,
  }) {
    return Stroke(
      color: color ?? this.color,
      brushSize: brushSize ?? this.brushSize,
      points: points ?? List<Offset>.from(this.points),
      shape: shape ?? this.shape,
      style: style ?? this.style,
      isEraser: isEraser ?? this.isEraser,
      isPencil: isPencil ?? this.isPencil,
      rasterImage: rasterImage ?? this.rasterImage,
      rasterBounds: rasterBounds ?? this.rasterBounds,
      textRun: textRun ?? this.textRun,
    );
  }
}
