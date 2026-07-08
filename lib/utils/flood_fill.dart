import 'dart:typed_data';
import 'dart:ui';

/// Maps brush size (2–48) to the `image` package flood-fill threshold.
double floodFillToleranceFromBrushSize(double brushSize) {
  if (brushSize <= 2) {
    return 0;
  }
  return (brushSize - 2) * 2.5;
}

/// Traces the outer contour of a binary mask (`255` = inside).
List<Offset> traceMaskContour(Uint8List mask, int width, int height) {
  if (width <= 0 || height <= 0 || mask.isEmpty) {
    return const [];
  }

  var startX = -1;
  var startY = -1;
  outer:
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (mask[y * width + x] != 0) {
        startX = x;
        startY = y;
        break outer;
      }
    }
  }
  if (startX < 0) {
    return const [];
  }

  const dirs = <Offset>[
    Offset(1, 0),
    Offset(1, 1),
    Offset(0, 1),
    Offset(-1, 1),
    Offset(-1, 0),
    Offset(-1, -1),
    Offset(0, -1),
    Offset(1, -1),
  ];

  final contour = <Offset>[];
  var x = startX;
  var y = startY;
  var dirIndex = 0;
  final start = Offset(x.toDouble(), y.toDouble());
  var guard = 0;
  final maxSteps = width * height * 8;

  do {
    contour.add(Offset(x + 0.5, y + 0.5));
    var found = false;
    for (var i = 0; i < 8; i++) {
      final idx = (dirIndex + i) % 8;
      final nx = x + dirs[idx].dx.toInt();
      final ny = y + dirs[idx].dy.toInt();
      if (nx >= 0 &&
          nx < width &&
          ny >= 0 &&
          ny < height &&
          mask[ny * width + nx] != 0) {
        x = nx;
        y = ny;
        dirIndex = (idx + 6) % 8;
        found = true;
        break;
      }
    }
    if (!found) {
      break;
    }
    guard++;
  } while ((x.toDouble() != start.dx ||
          y.toDouble() != start.dy ||
          contour.length < 3) &&
      guard < maxSteps);

  return contour;
}

Rect? boundsOfMask(Uint8List mask, int width, int height) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (mask[y * width + x] == 0) {
        continue;
      }
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
  }

  if (maxX < 0) {
    return null;
  }

  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    maxX + 1.0,
    maxY + 1.0,
  );
}
