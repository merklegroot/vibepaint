import 'package:flutter/material.dart';

class Stroke {
  Stroke({
    required this.color,
    required this.brushSize,
    List<Offset>? points,
  }) : points = points ?? [];

  final Color color;
  final double brushSize;
  final List<Offset> points;

  bool get isEmpty => points.isEmpty;

  Stroke copyWith({
    Color? color,
    double? brushSize,
    List<Offset>? points,
  }) {
    return Stroke(
      color: color ?? this.color,
      brushSize: brushSize ?? this.brushSize,
      points: points ?? List<Offset>.from(this.points),
    );
  }
}
