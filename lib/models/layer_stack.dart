import 'dart:ui' as ui;

import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';

class LayerStack {
  LayerStack({Iterable<Stroke>? initialStrokes}) {
    _layers.add(
      PaintLayer(
        name: 'Layer 1',
        history: StrokeHistory(initialStrokes),
      ),
    );
  }

  final List<PaintLayer> _layers = [];
  int _activeIndex = 0;
  ui.Image? _backgroundImage;

  List<PaintLayer> get layers => List<PaintLayer>.unmodifiable(_layers);

  int get activeIndex => _activeIndex;

  PaintLayer get activeLayer => _layers[_activeIndex];

  StrokeHistory get activeHistory => activeLayer.history;

  ui.Image? get backgroundImage => _backgroundImage;

  bool get canUndo => activeHistory.canUndo;

  bool get canRedo => activeHistory.canRedo;

  bool get hasContent =>
      _backgroundImage != null ||
      _layers.any((layer) => layer.history.canUndo);

  bool get canDeleteActiveLayer => _layers.length > 1;

  void setBackgroundImage(ui.Image? image) {
    _backgroundImage?.dispose();
    _backgroundImage = image;
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

  void addLayer() {
    final number = _layers.length + 1;
    _layers.add(PaintLayer(name: 'Layer $number'));
    _activeIndex = _layers.length - 1;
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
    _layers
      ..clear()
      ..add(PaintLayer(name: 'Layer 1'));
    _activeIndex = 0;
  }

  void dispose() {
    _backgroundImage?.dispose();
    _backgroundImage = null;
  }
}
