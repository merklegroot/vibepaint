import 'dart:ui';

enum SelectionShape {
  rectangle,
  ellipse,
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
    }
    return CanvasSelection(
      shape: shape,
      path: path,
      bounds: normalized,
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

  bool get canReshape => isSimple && !isEmpty;

  bool contains(Offset point) => path.contains(point);

  CanvasSelection withShape(SelectionShape newShape) {
    if (!isSimple) {
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
