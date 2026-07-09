import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/text_run.dart';

enum StrokeShape {
  freehand,
  line,
  rectangle,
  ellipse,
  gradient,
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
    this.secondaryColor,
    this.isEraser = false,
    this.isPencil = false,
    this.isStudioBrush = false,
    this.brushOpacity = 1,
    List<double>? pressures,
    this.rasterImage,
    this.rasterBounds,
    this.textRun,
  })  : points = points ?? [],
        pressures = pressures ?? [];

  final Color color;
  final double brushSize;
  final List<Offset> points;
  final List<double> pressures;
  final StrokeShape shape;
  final ShapeStyle style;
  final Color? secondaryColor;
  final bool isEraser;
  final bool isPencil;
  final bool isStudioBrush;
  final double brushOpacity;
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
    Color? secondaryColor,
    bool? isEraser,
    bool? isPencil,
    bool? isStudioBrush,
    double? brushOpacity,
    List<double>? pressures,
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
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isEraser: isEraser ?? this.isEraser,
      isPencil: isPencil ?? this.isPencil,
      isStudioBrush: isStudioBrush ?? this.isStudioBrush,
      brushOpacity: brushOpacity ?? this.brushOpacity,
      pressures: pressures ?? List<double>.from(this.pressures),
      rasterImage: rasterImage ?? this.rasterImage,
      rasterBounds: rasterBounds ?? this.rasterBounds,
      textRun: textRun ?? this.textRun,
    );
  }
}
