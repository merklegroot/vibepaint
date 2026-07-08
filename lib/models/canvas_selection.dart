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
  });

  final SelectionShape shape;
  final Path path;
  final Rect bounds;

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
    );
  }

  factory CanvasSelection.all(Size canvasSize) {
    return CanvasSelection.fromRect(
      SelectionShape.rectangle,
      Offset.zero & canvasSize,
    );
  }

  bool get isEmpty => bounds.isEmpty || bounds.width <= 0 || bounds.height <= 0;

  bool contains(Offset point) => path.contains(point);

  CanvasSelection inverted(Size canvasSize) {
    final outer = Path()..addRect(Offset.zero & canvasSize);
    return CanvasSelection(
      shape: shape,
      path: Path.combine(PathOperation.difference, outer, path),
      bounds: Offset.zero & canvasSize,
    );
  }

  CanvasSelection combined(CanvasSelection other, PathOperation operation) {
    return CanvasSelection(
      shape: shape,
      path: Path.combine(operation, path, other.path),
      bounds: bounds.expandToInclude(other.bounds),
    );
  }

  static Rect _normalizeRect(Rect rect) {
    if (rect.width < 0 || rect.height < 0) {
      return Rect.fromPoints(rect.topLeft, rect.bottomRight);
    }
    return rect;
  }
}
