import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// Which color well receives preset palette clicks.
enum ColorWellTarget {
  primary,
  canvasBackground,
}

/// Default primary (foreground) color index — black (bottom row, first column).
const defaultPrimaryColorIndex = AppColors.presetColorColumns;

/// Default canvas background for a new document.
const defaultCanvasBackground = Colors.white;

/// Canvas background with no fill — transparent areas show a checkerboard.
const transparentCanvasBackground = Colors.transparent;

bool isTransparentCanvasBackground(Color color) => color.a == 0;

String colorWellHex(Color color) {
  if (isTransparentCanvasBackground(color)) {
    return 'Transparent';
  }
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

int? presetColorIndex(Color color) {
  for (var i = 0; i < AppColors.presetColors.length; i++) {
    if (AppColors.presetColors[i].toARGB32() == color.toARGB32()) {
      return i;
    }
  }
  return null;
}

/// Small checkerboard used in color wells and dialogs.
class CanvasCheckerboardPainter extends CustomPainter {
  const CanvasCheckerboardPainter({this.cellSize = 5});

  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    const light = Color(0xFFCCCCCC);
    const dark = Color(0xFF999999);

    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final row = (y / cellSize).floor();
        final col = (x / cellSize).floor();
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          Paint()..color = (row + col).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasCheckerboardPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize;
}
