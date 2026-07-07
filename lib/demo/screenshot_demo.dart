import 'package:flutter/material.dart';
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
  ];
}
