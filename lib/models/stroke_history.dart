import 'package:vibepaint/models/history_action.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/history_labels.dart';

class StrokeHistory {
  StrokeHistory([Iterable<Stroke>? initial]) {
    if (initial != null && initial.isNotEmpty) {
      _applied.add(
        HistoryAction(
          label: 'Open image',
          strokes: _cloneStrokes(initial),
        ),
      );
    }
  }

  StrokeHistory.fromState(List<Stroke> strokes, {required String label}) {
    if (strokes.isNotEmpty) {
      _applied.add(
        HistoryAction(
          label: label,
          strokes: _cloneStrokes(strokes),
        ),
      );
    }
  }

  final List<HistoryAction> _applied = [];
  final List<HistoryAction> _redo = [];
  List<Stroke>? _previewStrokes;

  List<Stroke> get strokes =>
      _previewStrokes ??
      (_applied.isEmpty ? const [] : _applied.last.strokes);

  bool get canUndo => _applied.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

  int get currentIndex => _applied.length - 1;

  List<HistoryAction> get appliedActions =>
      List<HistoryAction>.unmodifiable(_applied);

  List<HistoryAction> get timeline => [
        ..._applied,
        ..._redo.reversed,
      ];

  bool isUndone(int index) => index >= _applied.length;

  void add(Stroke stroke, {String? label}) {
    commitStrokes(
      label ?? historyLabelForStroke(stroke),
      [...strokes, stroke],
    );
  }

  void commitStrokes(String label, List<Stroke> strokes) {
    clearPreview();
    _applied.add(
      HistoryAction(
        label: label,
        strokes: _cloneStrokes(strokes),
      ),
    );
    _redo.clear();
  }

  void replaceStrokes(List<Stroke> strokes) {
    _previewStrokes = _cloneStrokes(strokes);
  }

  void clearPreview() {
    _previewStrokes = null;
  }

  bool undo() {
    if (!canUndo) {
      return false;
    }

    clearPreview();
    _redo.add(_applied.removeLast());
    return true;
  }

  bool redo() {
    if (!canRedo) {
      return false;
    }

    clearPreview();
    _applied.add(_redo.removeLast());
    return true;
  }

  void goToIndex(int index) {
    clearPreview();
    final target = index.clamp(-1, timeline.length - 1);
    while (currentIndex > target) {
      if (!undo()) {
        break;
      }
    }
    while (currentIndex < target) {
      if (!redo()) {
        break;
      }
    }
  }

  void clear() {
    _applied.clear();
    _redo.clear();
    clearPreview();
  }

  void appendAll(Iterable<Stroke> strokes, {String label = 'Merge layer'}) {
    commitStrokes(label, [...this.strokes, ...strokes]);
  }

  void removeWhere(bool Function(Stroke stroke) test, {String label = 'Delete'}) {
    commitStrokes(
      label,
      [for (final stroke in strokes) if (!test(stroke)) stroke],
    );
  }

  List<Stroke> _cloneStrokes(Iterable<Stroke> strokes) {
    return [for (final stroke in strokes) stroke.copyWith()];
  }
}
