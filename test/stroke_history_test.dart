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

    expect(history.undo(), isTrue);
    expect(history.strokes, isEmpty);
    expect(history.canRedo, isTrue);

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
}
