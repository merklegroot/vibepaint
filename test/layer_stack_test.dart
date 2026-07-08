import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/stroke.dart';

void main() {
  test('starts with one layer and empty history', () {
    final stack = LayerStack();

    expect(stack.layers, hasLength(1));
    expect(stack.layers.first.name, 'Background');
    expect(stack.activeIndex, 0);
    expect(stack.canUndo, isFalse);
    expect(stack.hasContent, isFalse);
  });

  test('add layer inserts above active layer', () {
    final stack = LayerStack();

    stack.addLayer();

    expect(stack.layers, hasLength(2));
    expect(stack.activeIndex, 1);
    expect(stack.layers[1].name, 'Layer 2');
  });

  test('undo and redo operate on active layer only', () {
    final stack = LayerStack();
    stack.addLayer();

    stack.layers[0].history.add(
          Stroke(color: Colors.red, brushSize: 4, points: const [Offset(1, 1)]),
        );
    stack.setActiveLayer(1);
    stack.activeHistory.add(
      Stroke(color: Colors.blue, brushSize: 4, points: const [Offset(2, 2)]),
    );

    expect(stack.layers[0].history.strokes, hasLength(1));
    expect(stack.layers[1].history.strokes, hasLength(1));

    expect(stack.activeHistory.undo(), isTrue);
    expect(stack.layers[1].history.strokes, isEmpty);
    expect(stack.layers[0].history.strokes, hasLength(1));
  });

  test('duplicate layer copies strokes above source', () {
    final stack = LayerStack();
    stack.activeHistory.add(
      Stroke(color: Colors.red, brushSize: 4, points: const [Offset(1, 1)]),
    );

    stack.duplicateLayer(0);

    expect(stack.layers, hasLength(2));
    expect(stack.activeIndex, 1);
    expect(stack.layers[1].history.strokes, hasLength(1));
    expect(stack.layers[1].name, 'Background copy');
  });

  test('move layer up increases z-index', () {
    final stack = LayerStack();
    stack.addLayer();

    stack.moveLayerUp(0);

    expect(stack.layers[0].name, 'Layer 2');
    expect(stack.layers[1].name, 'Background');
  });

  test('merge down combines strokes into lower layer', () {
    final stack = LayerStack();
    stack.addLayer();
    stack.layers[0].history.add(
          Stroke(color: Colors.red, brushSize: 4, points: const [Offset(1, 1)]),
        );
    stack.layers[1].history.add(
          Stroke(color: Colors.blue, brushSize: 4, points: const [Offset(2, 2)]),
        );

    stack.mergeDown(1);

    expect(stack.layers, hasLength(1));
    expect(stack.layers[0].history.strokes, hasLength(2));
  });

  test('rename and opacity update layer properties', () {
    final stack = LayerStack();

    stack.renameLayer(0, 'Background');
    stack.setLayerOpacity(0, 0.5);
    stack.setLayerBlendMode(0, LayerBlendMode.multiply);

    expect(stack.layers[0].name, 'Background');
    expect(stack.layers[0].opacity, 0.5);
    expect(stack.layers[0].blendMode, LayerBlendMode.multiply);
  });

  test('delete layer adjusts active index', () {
    final stack = LayerStack();
    stack.addLayer();
    stack.setActiveLayer(1);

    stack.deleteLayer(1);

    expect(stack.layers, hasLength(1));
    expect(stack.activeIndex, 0);
  });

  test('toggle visibility updates layer', () {
    final stack = LayerStack();

    expect(stack.layers.first.visible, isTrue);
    stack.toggleVisibility(0);
    expect(stack.layers.first.visible, isFalse);
  });

  test('clear resets to a single empty layer', () {
    final stack = LayerStack(
      initialStrokes: [
        Stroke(color: Colors.red, brushSize: 4, points: const [Offset(1, 1)]),
      ],
    );
    stack.addLayer();

    stack.clear();

    expect(stack.layers, hasLength(1));
    expect(stack.layers.first.name, 'Background');
    expect(stack.layers.first.history.strokes, isEmpty);
    expect(stack.backgroundImage, isNull);
    expect(stack.hasContent, isFalse);
  });
}
