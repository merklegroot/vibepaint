import 'dart:math';

import 'package:flutter/services.dart';

enum SelectionResizeHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

const _minSelectionSize = 4.0;
const _edgeHitRadius = 6.0;
const _cornerHitRadius = 8.0;

const _cornerHandles = [
  SelectionResizeHandle.topLeft,
  SelectionResizeHandle.topRight,
  SelectionResizeHandle.bottomLeft,
  SelectionResizeHandle.bottomRight,
];

const _edgeHandles = [
  SelectionResizeHandle.topCenter,
  SelectionResizeHandle.centerLeft,
  SelectionResizeHandle.centerRight,
  SelectionResizeHandle.bottomCenter,
];

bool isCornerSelectionHandle(SelectionResizeHandle handle) {
  return switch (handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.topRight ||
    SelectionResizeHandle.bottomLeft ||
    SelectionResizeHandle.bottomRight =>
      true,
    _ => false,
  };
}

Map<SelectionResizeHandle, Offset> selectionHandlePositionsMap(Rect bounds) {
  return {
    SelectionResizeHandle.topLeft: bounds.topLeft,
    SelectionResizeHandle.topCenter: Offset(bounds.center.dx, bounds.top),
    SelectionResizeHandle.topRight: bounds.topRight,
    SelectionResizeHandle.centerLeft: Offset(bounds.left, bounds.center.dy),
    SelectionResizeHandle.centerRight: Offset(bounds.right, bounds.center.dy),
    SelectionResizeHandle.bottomLeft: bounds.bottomLeft,
    SelectionResizeHandle.bottomCenter: Offset(bounds.center.dx, bounds.bottom),
    SelectionResizeHandle.bottomRight: bounds.bottomRight,
  };
}

SelectionResizeHandle? hitTestSelectionHandle(Offset point, Rect bounds) {
  final positions = selectionHandlePositionsMap(bounds);

  for (final handle in _cornerHandles) {
    if ((positions[handle]! - point).distance <= _cornerHitRadius) {
      return handle;
    }
  }

  for (final handle in _edgeHandles) {
    if ((positions[handle]! - point).distance <= _edgeHitRadius) {
      return handle;
    }
  }

  return null;
}

SystemMouseCursor cursorForSelectionHandle(SelectionResizeHandle handle) {
  return switch (handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.bottomRight =>
      SystemMouseCursors.resizeUpLeftDownRight,
    SelectionResizeHandle.topRight ||
    SelectionResizeHandle.bottomLeft =>
      SystemMouseCursors.resizeUpRightDownLeft,
    SelectionResizeHandle.topCenter ||
    SelectionResizeHandle.bottomCenter =>
      SystemMouseCursors.resizeUpDown,
    SelectionResizeHandle.centerLeft ||
    SelectionResizeHandle.centerRight =>
      SystemMouseCursors.resizeLeftRight,
  };
}

Rect resizeSelectionBounds({
  required Rect original,
  required SelectionResizeHandle handle,
  required Offset current,
  required Rect canvasBounds,
  bool constrainSquare = false,
}) {
  var left = original.left;
  var top = original.top;
  var right = original.right;
  var bottom = original.bottom;

  switch (handle) {
    case SelectionResizeHandle.topLeft:
      left = current.dx;
      top = current.dy;
    case SelectionResizeHandle.topCenter:
      top = current.dy;
    case SelectionResizeHandle.topRight:
      right = current.dx;
      top = current.dy;
    case SelectionResizeHandle.centerLeft:
      left = current.dx;
    case SelectionResizeHandle.centerRight:
      right = current.dx;
    case SelectionResizeHandle.bottomLeft:
      left = current.dx;
      bottom = current.dy;
    case SelectionResizeHandle.bottomCenter:
      bottom = current.dy;
    case SelectionResizeHandle.bottomRight:
      right = current.dx;
      bottom = current.dy;
  }

  if (constrainSquare) {
    final width = (right - left).abs();
    final height = (bottom - top).abs();
    final size = max(width, height);
    switch (handle) {
      case SelectionResizeHandle.topLeft:
        left = right - size * (right >= left ? 1 : -1);
        top = bottom - size * (bottom >= top ? 1 : -1);
      case SelectionResizeHandle.topRight:
        right = left + size * (right >= left ? 1 : -1);
        top = bottom - size * (bottom >= top ? 1 : -1);
      case SelectionResizeHandle.bottomLeft:
        left = right - size * (right >= left ? 1 : -1);
        bottom = top + size * (bottom >= top ? 1 : -1);
      case SelectionResizeHandle.bottomRight:
        right = left + size * (right >= left ? 1 : -1);
        bottom = top + size * (bottom >= top ? 1 : -1);
      default:
        break;
    }
  }

  var rect = Rect.fromLTRB(left, top, right, bottom);
  rect = _clampRect(rect, canvasBounds);
  rect = _enforceMinimumSize(rect, handle, original);
  return Rect.fromPoints(rect.topLeft, rect.bottomRight);
}

Rect _clampRect(Rect rect, Rect canvasBounds) {
  var left = rect.left.clamp(canvasBounds.left, canvasBounds.right);
  var top = rect.top.clamp(canvasBounds.top, canvasBounds.bottom);
  var right = rect.right.clamp(canvasBounds.left, canvasBounds.right);
  var bottom = rect.bottom.clamp(canvasBounds.top, canvasBounds.bottom);
  return Rect.fromLTRB(left, top, right, bottom);
}

Rect _enforceMinimumSize(
  Rect rect,
  SelectionResizeHandle handle,
  Rect original,
) {
  if (rect.width.abs() >= _minSelectionSize &&
      rect.height.abs() >= _minSelectionSize) {
    return rect;
  }

  return original;
}

List<Offset> selectionHandlePositions(Rect bounds) {
  return selectionHandlePositionsMap(bounds).values.toList();
}
