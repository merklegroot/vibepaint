import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/stroke_history.dart';

class PaintLayer {
  PaintLayer({
    required this.name,
    StrokeHistory? history,
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = LayerBlendMode.normal,
  }) : history = history ?? StrokeHistory();

  String name;
  final StrokeHistory history;
  bool visible;
  double opacity;
  LayerBlendMode blendMode;
}
