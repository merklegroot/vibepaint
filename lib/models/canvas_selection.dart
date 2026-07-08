import 'dart:ui';

enum SelectionShape {
  rectangle,
  ellipse,
  lasso,
}

class CanvasSelection {
  const CanvasSelection({
    required this.shape,
    required this.path,
    required this.bounds,
    this.isSimple = false,
  });

  final SelectionShape shape;
  final Path path;
  final Rect bounds;
  final bool isSimple;

  factory CanvasSelection.fromRect(SelectionShape shape, Rect rect) {
    final normalized = _normalizeRect(rect);
    final path = Path();
    switch (shape) {
      case SelectionShape.rectangle:
        path.addRect(normalized);
      case SelectionShape.ellipse:
        path.addOval(normalized);
      case SelectionShape.lasso:
        break;
    }
    return CanvasSelection(
      shape: shape,
      path: path,
      bounds: normalized,
      isSimple: true,
    );
  }

  factory CanvasSelection.fromPoints(
    List<Offset> points, {
    bool close = true,
  }) {
    if (points.isEmpty) {
      return CanvasSelection(
        shape: SelectionShape.lasso,
        path: Path(),
        bounds: Rect.zero,
        isSimple: true,
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (close && points.length >= 3) {
      path.close();
    }

    final bounds = path.getBounds();
    final isEmpty = close
        ? points.length < 3 ||
            (bounds.width <= 0 && bounds.height <= 0)
        : points.length < 2;

    return CanvasSelection(
      shape: SelectionShape.lasso,
      path: path,
      bounds: isEmpty ? Rect.zero : bounds,
      isSimple: true,
    );
  }

  factory CanvasSelection.all(Size canvasSize) {
    return CanvasSelection.fromRect(
      SelectionShape.rectangle,
      Offset.zero & canvasSize,
    );
  }

  bool get isEmpty => bounds.isEmpty || bounds.width <= 0 || bounds.height <= 0;

  bool get canReshape =>
      isSimple && !isEmpty && shape != SelectionShape.lasso;

  bool contains(Offset point) => path.contains(point);

  CanvasSelection withShape(SelectionShape newShape) {
    if (!isSimple || shape == SelectionShape.lasso) {
      return this;
    }
    return CanvasSelection.fromRect(newShape, bounds);
  }

  CanvasSelection withBounds(Rect rect) {
    if (!isSimple) {
      return this;
    }
    return CanvasSelection.fromRect(shape, rect);
  }

  CanvasSelection inverted(Size canvasSize) {
    final outer = Path()..addRect(Offset.zero & canvasSize);
    return CanvasSelection(
      shape: shape,
      path: Path.combine(PathOperation.difference, outer, path),
      bounds: Offset.zero & canvasSize,
      isSimple: false,
    );
  }

  CanvasSelection combined(CanvasSelection other, PathOperation operation) {
    return CanvasSelection(
      shape: shape,
      path: Path.combine(operation, path, other.path),
      bounds: bounds.expandToInclude(other.bounds),
      isSimple: false,
    );
  }

  static Rect _normalizeRect(Rect rect) {
    return Rect.fromPoints(rect.topLeft, rect.bottomRight);
  }
}
