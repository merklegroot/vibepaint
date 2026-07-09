import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart';

String historyLabelForStroke(Stroke stroke) {
  if (stroke.isEraser) {
    return 'Erase';
  }

  return switch (stroke.shape) {
    StrokeShape.freehand =>
      stroke.isPencil ? 'Pencil stroke' : 'Brush stroke',
    StrokeShape.line => 'Line',
    StrokeShape.rectangle =>
      stroke.style.drawsFill ? 'Filled rectangle' : 'Rectangle',
    StrokeShape.ellipse =>
      stroke.style.drawsFill ? 'Filled ellipse' : 'Ellipse',
    StrokeShape.gradient => 'Gradient',
    StrokeShape.raster => 'Edit image',
    StrokeShape.text => 'Text',
  };
}
