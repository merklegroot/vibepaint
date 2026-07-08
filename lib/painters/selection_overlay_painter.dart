import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/utils/selection_handles.dart';

class SelectionOverlayPainter extends CustomPainter {
  SelectionOverlayPainter({
    required this.selection,
    required this.dashPhase,
    this.showHandles = false,
  });

  final CanvasSelection? selection;
  final double dashPhase;
  final bool showHandles;

  static const _dashLength = 4.0;
  static const _gapLength = 4.0;
  static const _cornerHandleSize = 8.0;
  static const _edgeHandleSize = 6.0;

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

    if (showHandles && selection!.canReshape) {
      _drawHandles(canvas, selection!.bounds);
    }
  }

  static void _drawHandles(Canvas canvas, Rect bounds) {
    final fill = Paint()..color = Colors.white;
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final entry in selectionHandlePositionsMap(bounds).entries) {
      final size = isCornerSelectionHandle(entry.key)
          ? _cornerHandleSize
          : _edgeHandleSize;
      final rect = Rect.fromCenter(
        center: entry.value,
        width: size,
        height: size,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
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
        oldDelegate.dashPhase != dashPhase ||
        oldDelegate.showHandles != showHandles;
  }
}
