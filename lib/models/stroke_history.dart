import 'package:vibepaint/models/stroke.dart';

class StrokeHistory {
  StrokeHistory([Iterable<Stroke>? initial]) {
    _strokes.addAll(initial ?? const []);
  }

  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];

  List<Stroke> get strokes => List<Stroke>.unmodifiable(_strokes);

  bool get canUndo => _strokes.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  void add(Stroke stroke) {
    _strokes.add(stroke);
    _redoStack.clear();
  }

  bool undo() {
    if (!canUndo) {
      return false;
    }

    _redoStack.add(_strokes.removeLast());
    return true;
  }

  bool redo() {
    if (!canRedo) {
      return false;
    }

    _strokes.add(_redoStack.removeLast());
    return true;
  }

  void clear() {
    _strokes.clear();
    _redoStack.clear();
  }

  void appendAll(Iterable<Stroke> strokes) {
    _strokes.addAll(strokes);
    _redoStack.clear();
  }
}
