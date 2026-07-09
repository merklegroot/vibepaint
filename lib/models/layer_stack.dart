import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';
import 'package:vibepaint/theme/color_wells.dart';

class LayerStack {
  LayerStack({Iterable<Stroke>? initialStrokes}) {
    _layers.add(
      PaintLayer(
        name: 'Background',
        history: StrokeHistory(initialStrokes),
      ),
    );
  }

  final List<PaintLayer> _layers = [];
  int _activeIndex = 0;
  ui.Image? _backgroundImage;
  Color _backgroundColor = defaultCanvasBackground;

  List<PaintLayer> get layers => List<PaintLayer>.unmodifiable(_layers);

  int get activeIndex => _activeIndex;

  PaintLayer get activeLayer => _layers[_activeIndex];

  StrokeHistory get activeHistory => activeLayer.history;

  ui.Image? get backgroundImage => _backgroundImage;

  Color get backgroundColor => _backgroundColor;

  bool get canUndo => activeHistory.canUndo;

  bool get canRedo => activeHistory.canRedo;

  bool get hasContent =>
      _backgroundImage != null ||
      _backgroundColor != defaultCanvasBackground ||
      _layers.any((layer) => layer.history.canUndo);

  bool get canDeleteLayer => _layers.length > 1;

  bool canMoveLayerUp(int index) => index >= 0 && index < _layers.length - 1;

  bool canMoveLayerDown(int index) => index > 0;

  bool canMergeDown(int index) => index > 0;

  void setBackgroundImage(ui.Image? image) {
    _backgroundImage?.dispose();
    _backgroundImage = image;
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
  }

  void setActiveLayer(int index) {
    if (index < 0 || index >= _layers.length) {
      return;
    }
    _activeIndex = index;
  }

  void toggleVisibility(int index) {
    if (index < 0 || index >= _layers.length) {
      return;
    }
    _layers[index].visible = !_layers[index].visible;
  }

  void setLayerOpacity(int index, double opacity) {
    if (index < 0 || index >= _layers.length) {
      return;
    }
    _layers[index].opacity = opacity.clamp(0.0, 1.0);
  }

  void setLayerBlendMode(int index, LayerBlendMode blendMode) {
    if (index < 0 || index >= _layers.length) {
      return;
    }
    _layers[index].blendMode = blendMode;
  }

  void renameLayer(int index, String name) {
    if (index < 0 || index >= _layers.length) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _layers[index].name = trimmed;
  }

  void addLayer() {
    final insertAt = _activeIndex + 1;
    _layers.insert(
      insertAt,
      PaintLayer(name: _nextLayerName()),
    );
    _activeIndex = insertAt;
  }

  void duplicateLayer(int index) {
    if (index < 0 || index >= _layers.length) {
      return;
    }

    final source = _layers[index];
    final copy = PaintLayer(
      name: '${source.name} copy',
      history: StrokeHistory.fromState(
        List<Stroke>.from(source.history.strokes),
        label: 'Duplicate layer',
      ),
      visible: source.visible,
      opacity: source.opacity,
      blendMode: source.blendMode,
    );
    _layers.insert(index + 1, copy);
    _activeIndex = index + 1;
  }

  void moveLayerUp(int index) {
    if (!canMoveLayerUp(index)) {
      return;
    }

    final layer = _layers.removeAt(index);
    _layers.insert(index + 1, layer);
    if (_activeIndex == index) {
      _activeIndex = index + 1;
    } else if (_activeIndex == index + 1) {
      _activeIndex = index;
    }
  }

  void moveLayerDown(int index) {
    if (!canMoveLayerDown(index)) {
      return;
    }

    final layer = _layers.removeAt(index);
    _layers.insert(index - 1, layer);
    if (_activeIndex == index) {
      _activeIndex = index - 1;
    } else if (_activeIndex == index - 1) {
      _activeIndex = index;
    }
  }

  void mergeDown(int index) {
    if (!canMergeDown(index)) {
      return;
    }

    final upper = _layers[index];
    final lower = _layers[index - 1];
    lower.history.appendAll(upper.history.strokes);
    _layers.removeAt(index);
    if (_activeIndex >= _layers.length) {
      _activeIndex = _layers.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
  }

  void deleteLayer(int index) {
    if (_layers.length <= 1 || index < 0 || index >= _layers.length) {
      return;
    }

    _layers.removeAt(index);
    if (_activeIndex >= _layers.length) {
      _activeIndex = _layers.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
  }

  void clear() {
    for (final layer in _layers) {
      layer.history.clear();
    }
    _backgroundImage?.dispose();
    _backgroundImage = null;
    _backgroundColor = defaultCanvasBackground;
    _layers
      ..clear()
      ..add(PaintLayer(name: 'Background'));
    _activeIndex = 0;
  }

  void dispose() {
    _backgroundImage?.dispose();
    _backgroundImage = null;
  }

  String _nextLayerName() {
    var number = _layers.length + 1;
    while (_layers.any((layer) => layer.name == 'Layer $number')) {
      number++;
    }
    return 'Layer $number';
  }
}
