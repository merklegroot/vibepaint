import 'package:flutter/material.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart';

const double screenshotBrushSize = 6;

List<Stroke> screenshotDemoStrokes() {
  return [
    Stroke(
      color: const Color(0xFFFF0000),
      brushSize: screenshotBrushSize,
      points: const [
        Offset(280, 340),
        Offset(440, 200),
        Offset(600, 360),
        Offset(760, 240),
      ],
    ),
    Stroke(
      color: const Color(0xFF0000FF),
      brushSize: screenshotBrushSize,
      points: const [
        Offset(360, 420),
        Offset(520, 320),
        Offset(680, 400),
      ],
    ),
    Stroke(
      color: const Color(0xFF00AA00),
      brushSize: 4,
      points: const [Offset(300, 260), Offset(560, 260)],
      shape: StrokeShape.line,
    ),
    Stroke(
      color: const Color(0xFFFF8800),
      brushSize: 4,
      points: const [Offset(320, 380), Offset(500, 500)],
      shape: StrokeShape.rectangle,
      style: ShapeStyle.filled,
    ),
    Stroke(
      color: const Color(0xFF8800FF),
      brushSize: 4,
      points: const [Offset(580, 300), Offset(760, 460)],
      shape: StrokeShape.ellipse,
      style: ShapeStyle.filledOutline,
    ),
  ];
}
