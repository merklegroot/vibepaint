import 'package:flutter/material.dart';

import 'package:vibepaint/models/shape_style.dart';

enum StrokeShape {
  freehand,
  line,
  rectangle,
  ellipse,
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
  }) : points = points ?? [];

  final Color color;
  final double brushSize;
  final List<Offset> points;
  final StrokeShape shape;
  final ShapeStyle style;
  final bool isEraser;
  final bool isPencil;

  bool get isEmpty => points.isEmpty;

  Stroke copyWith({
    Color? color,
    double? brushSize,
    List<Offset>? points,
    StrokeShape? shape,
    ShapeStyle? style,
    bool? isEraser,
    bool? isPencil,
  }) {
    return Stroke(
      color: color ?? this.color,
      brushSize: brushSize ?? this.brushSize,
      points: points ?? List<Offset>.from(this.points),
      shape: shape ?? this.shape,
      style: style ?? this.style,
      isEraser: isEraser ?? this.isEraser,
      isPencil: isPencil ?? this.isPencil,
    );
  }
}
