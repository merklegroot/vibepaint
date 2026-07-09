import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';

void main() {
  test('undo and redo stroke history', () {
    final history = StrokeHistory();
    final stroke = Stroke(
      color: Colors.red,
      brushSize: 4,
      points: const [Offset(1, 2)],
    );

    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);

    history.add(stroke);
    expect(history.strokes, hasLength(1));
    expect(history.canUndo, isTrue);
    expect(history.timeline, hasLength(1));

    expect(history.undo(), isTrue);
    expect(history.strokes, isEmpty);
    expect(history.canRedo, isTrue);
    expect(history.timeline, hasLength(1));

    expect(history.redo(), isTrue);
    expect(history.strokes, hasLength(1));
    expect(history.canRedo, isFalse);
  });

  test('new stroke clears redo stack', () {
    final history = StrokeHistory();
    history.add(Stroke(color: Colors.red, brushSize: 4));
    history.undo();

    history.add(Stroke(color: Colors.blue, brushSize: 4));

    expect(history.canRedo, isFalse);
    expect(history.strokes, hasLength(1));
    expect(history.strokes.first.color, Colors.blue);
  });

  test('clear removes all strokes and redo history', () {
    final history = StrokeHistory();
    history.add(Stroke(color: Colors.red, brushSize: 4));
    history.undo();

    history.clear();

    expect(history.strokes, isEmpty);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
  });

  test('goToIndex jumps through timeline', () {
    final history = StrokeHistory();
    history.add(Stroke(color: Colors.red, brushSize: 4), label: 'First');
    history.add(Stroke(color: Colors.green, brushSize: 4), label: 'Second');
    history.add(Stroke(color: Colors.blue, brushSize: 4), label: 'Third');

    expect(history.currentIndex, 2);
    expect(history.strokes, hasLength(3));

    history.goToIndex(0);
    expect(history.currentIndex, 0);
    expect(history.strokes, hasLength(1));
    expect(history.canRedo, isTrue);

    history.goToIndex(2);
    expect(history.currentIndex, 2);
    expect(history.strokes, hasLength(3));
    expect(history.canRedo, isFalse);
  });

  test('preview does not record history until commit', () {
    final history = StrokeHistory();
    history.add(Stroke(color: Colors.red, brushSize: 4));

    history.replaceStrokes([
      Stroke(color: Colors.blue, brushSize: 4),
    ]);

    expect(history.timeline, hasLength(1));
    expect(history.strokes.first.color, Colors.blue);

    history.clearPreview();
    expect(history.strokes.first.color, Colors.red);

    history.commitStrokes('Effect', [
      Stroke(color: Colors.green, brushSize: 4),
    ]);
    expect(history.timeline, hasLength(2));
    expect(history.timeline.last.label, 'Effect');
  });
}
