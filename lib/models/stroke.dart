import 'package:flutter/material.dart';

enum StrokeShape {
  freehand,
  line,
  rectangle,
}

class Stroke {
  Stroke({
    required this.color,
    required this.brushSize,
    List<Offset>? points,
    this.shape = StrokeShape.freehand,
  }) : points = points ?? [];

  final Color color;
  final double brushSize;
  final List<Offset> points;
  final StrokeShape shape;

  bool get isEmpty => points.isEmpty;

  Stroke copyWith({
    Color? color,
    double? brushSize,
    List<Offset>? points,
    StrokeShape? shape,
  }) {
    return Stroke(
      color: color ?? this.color,
      brushSize: brushSize ?? this.brushSize,
      points: points ?? List<Offset>.from(this.points),
      shape: shape ?? this.shape,
    );
  }
}
