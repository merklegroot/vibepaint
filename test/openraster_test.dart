import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/formats/openraster/openraster_io.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imageFormatFromExtension recognizes ora', () {
    expect(imageFormatFromExtension('ora'), ImageFileFormat.ora);
  });

  test('writeOpenRasterBytes produces a readable layered document', () async {
    final layerStack = LayerStack(
      initialStrokes: [
        Stroke(
          color: Colors.red,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(40, 40)],
        ),
      ],
    );
    layerStack.addLayer();
    layerStack.activeHistory.add(
      Stroke(
        color: Colors.blue,
        brushSize: 4,
        points: const [Offset(50, 50), Offset(80, 80)],
      ),
      label: 'Draw',
    );

    const size = Size(100, 100);
    final bytes = await writeOpenRasterBytes(
      size: size,
      layerStack: layerStack,
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0x50)); // ZIP local file header

    final document = await readOpenRasterBytes(bytes);
    expect(document.size, size);
    expect(document.layers.length, greaterThanOrEqualTo(2));
    expect(document.layers.first.history.strokes, isNotEmpty);
  });

  test('readOpenRasterBytes loads layers from minimal archive', () async {
    final layerStack = LayerStack(
      initialStrokes: [
        Stroke(
          color: Colors.green,
          brushSize: 2,
          points: const [Offset(5, 5), Offset(20, 20)],
        ),
      ],
    );

    final bytes = await writeOpenRasterBytes(
      size: const Size(64, 64),
      layerStack: layerStack,
    );
    final document = await readOpenRasterBytes(bytes);

    expect(document.size, const Size(64, 64));
    expect(document.layers, isNotEmpty);
    expect(document.layers.last.name, 'Background');
  });

  test('round trip preserves layer metadata', () async {
    final layer = PaintLayer(
      name: 'Sketch',
      visible: false,
      opacity: 0.5,
      history: StrokeHistory([
        Stroke(
          color: Colors.black,
          brushSize: 2,
          points: const [Offset(1, 1), Offset(10, 10)],
        ),
      ]),
    );
    final layerStack = LayerStack();
    layerStack.loadLayers([layer]);

    final bytes = await writeOpenRasterBytes(
      size: const Size(32, 32),
      layerStack: layerStack,
    );
    final document = await readOpenRasterBytes(bytes);
    final loaded = document.layers.firstWhere((layer) => layer.name == 'Sketch');

    expect(loaded.name, 'Sketch');
    expect(loaded.visible, isFalse);
    expect(loaded.opacity, closeTo(0.5, 0.001));
    expect(loaded.history.strokes.single.shape, StrokeShape.raster);
  });
}
