import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';

class SelectionOverlayPainter extends CustomPainter {
  SelectionOverlayPainter({
    required this.selection,
    required this.dashPhase,
  });

  final CanvasSelection? selection;
  final double dashPhase;

  static const _dashLength = 4.0;
  static const _gapLength = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (selection == null || selection!.isEmpty) {
      return;
    }

    _drawDashedPath(
      canvas: canvas,
      path: selection!.path,
      color: Colors.black,
      phase: dashPhase,
    );
    _drawDashedPath(
      canvas: canvas,
      path: selection!.path,
      color: Colors.white,
      phase: dashPhase + _dashLength + _gapLength,
    );
  }

  static void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Color color,
    required double phase,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = phase % (_dashLength + _gapLength);
      while (distance < metric.length) {
        final end = distance + _dashLength;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SelectionOverlayPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.dashPhase != dashPhase;
  }
}
