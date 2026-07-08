import 'package:vibepaint/models/stroke_history.dart';

class PaintLayer {
  PaintLayer({
    required this.name,
    StrokeHistory? history,
    this.visible = true,
  }) : history = history ?? StrokeHistory();

  final String name;
  final StrokeHistory history;
  bool visible;
}
