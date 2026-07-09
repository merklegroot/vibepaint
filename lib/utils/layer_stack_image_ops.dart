import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/image_transforms.dart';

extension LayerStackImageOperations on LayerStack {
  void flattenLayers() {
    if (layers.length <= 1) {
      return;
    }

    final merged = <Stroke>[];
    for (final layer in layers) {
      merged.addAll(layer.history.strokes);
    }

    for (final layer in layers) {
      layer.history.clear();
    }
    activeHistory.commitStrokes('Flatten image', merged);
    while (layers.length > 1) {
      deleteLayer(layers.length - 1);
    }
    renameLayer(0, 'Background');
  }

  void flipHorizontal(Size canvasSize) {
    final axisX = canvasSize.width / 2;
    _transformAllStrokes(
      (point) => flipPointHorizontally(point, axisX),
      label: 'Flip horizontal',
    );
  }

  void flipVertical(Size canvasSize) {
    final axisY = canvasSize.height / 2;
    _transformAllStrokes(
      (point) => flipPointVertically(point, axisY),
      label: 'Flip vertical',
    );
  }

  void rotate90Clockwise(Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    _transformAllStrokes(
      (point) => rotateAround(point, center, -pi / 2),
      label: 'Rotate 90° CW',
    );
  }

  void rotate90CounterClockwise(Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    _transformAllStrokes(
      (point) => rotateAround(point, center, pi / 2),
      label: 'Rotate 90° CCW',
    );
  }

  void rotate180(Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    _transformAllStrokes(
      (point) => rotateAround(point, center, pi),
      label: 'Rotate 180°',
    );
  }

  void rotateContent(Size canvasSize, double radians) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    _transformAllStrokes(
      (point) => rotateAround(point, center, radians),
      label: 'Rotate',
    );
  }

  void resizeImageContent(Size currentSize, Size newSize) {
    final scaleX = newSize.width / currentSize.width;
    final scaleY = newSize.height / currentSize.height;
    final scale = sqrt(scaleX * scaleY);
    _transformAllStrokes(
      (point) => scaleAround(point, Offset.zero, scaleX, scaleY),
      brushSizeScale: scale,
      label: 'Resize image',
    );
  }

  void resizeCanvasContent({
    required Size currentSize,
    required Size newSize,
    CanvasAnchor anchor = CanvasAnchor.center,
  }) {
    if (newSize == currentSize) {
      return;
    }

    if (newSize.width < currentSize.width ||
        newSize.height < currentSize.height) {
      cropContentToRect(Rect.fromLTWH(0, 0, newSize.width, newSize.height));
      return;
    }

    final offset = canvasResizeOffset(
      currentSize: currentSize,
      newSize: newSize,
      anchor: anchor,
    );
    _transformAllStrokes(
      (point) => point + offset,
      label: 'Resize canvas',
    );
  }

  void cropContentToRect(Rect rect) {
    final normalized = Rect.fromPoints(rect.topLeft, rect.bottomRight);
    if (normalized.isEmpty) {
      return;
    }

    final cropRect = Rect.fromLTWH(0, 0, normalized.width, normalized.height);
    final offset = -normalized.topLeft;

    for (final layer in layers) {
      final clipped = <Stroke>[];
      for (final stroke in layer.history.strokes) {
        final shifted = transformStroke(stroke, (point) => point + offset);
        final result = clipStrokeToRect(shifted, cropRect);
        if (result != null) {
          clipped.add(result);
        }
      }
      layer.history.commitStrokes('Crop image', clipped);
    }
  }

  void cropContentToSelection(CanvasSelection selection) {
    final bounds = selection.bounds;
    if (bounds.isEmpty) {
      return;
    }

    final offset = -bounds.topLeft;
    final translatedSelection = translateSelection(selection, offset);

    for (final layer in layers) {
      final clipped = <Stroke>[];
      for (final stroke in layer.history.strokes) {
        final shifted = transformStroke(stroke, (point) => point + offset);
        final result = clipStrokeToSelection(shifted, translatedSelection);
        if (result != null) {
          clipped.add(result);
        }
      }
      layer.history.commitStrokes('Crop to selection', clipped);
    }
  }

  Future<void> transformBackgroundImage(
    img.Image Function(img.Image image) transform,
  ) async {
    final image = backgroundImage;
    if (image == null) {
      return;
    }

    final raster = await uiImageToRasterImage(image);
    final transformed = transform(raster);
    setBackgroundImage(await rasterImageToUiImage(transformed));
  }

  Future<void> cropBackgroundToRect(Rect rect, Size canvasSize) async {
    if (backgroundImage == null || rect.isEmpty) {
      return;
    }

    final normalized = Rect.fromPoints(rect.topLeft, rect.bottomRight);
    await transformBackgroundImage((raster) {
      final src = Rect.fromLTWH(
        normalized.left / canvasSize.width * raster.width,
        normalized.top / canvasSize.height * raster.height,
        normalized.width / canvasSize.width * raster.width,
        normalized.height / canvasSize.height * raster.height,
      );
      return img.copyCrop(
        raster,
        x: src.left.round().clamp(0, raster.width - 1),
        y: src.top.round().clamp(0, raster.height - 1),
        width: max(1, src.width.round()),
        height: max(1, src.height.round()),
      );
    });
  }

  Future<void> flipBackgroundHorizontal() async {
    await transformBackgroundImage(img.flipHorizontal);
  }

  Future<void> flipBackgroundVertical() async {
    await transformBackgroundImage(img.flipVertical);
  }

  Future<void> rotateBackground90Clockwise() async {
    await transformBackgroundImage((raster) => img.copyRotate(raster, angle: -90));
  }

  Future<void> rotateBackground90CounterClockwise() async {
    await transformBackgroundImage((raster) => img.copyRotate(raster, angle: 90));
  }

  Future<void> rotateBackground180() async {
    await transformBackgroundImage((raster) => img.copyRotate(raster, angle: 180));
  }

  Future<void> rotateBackgroundByDegrees(double degrees) async {
    await transformBackgroundImage((raster) {
      final rotated = img.copyRotate(raster, angle: degrees);
      final cropX = max(0, (rotated.width - raster.width) ~/ 2);
      final cropY = max(0, (rotated.height - raster.height) ~/ 2);
      return img.copyCrop(
        rotated,
        x: cropX,
        y: cropY,
        width: min(raster.width, rotated.width - cropX),
        height: min(raster.height, rotated.height - cropY),
      );
    });
  }

  Future<void> resizeBackgroundImage(Size currentSize, Size newSize) async {
    await transformBackgroundImage(
      (raster) => img.copyResize(
        raster,
        width: max(1, (raster.width * newSize.width / currentSize.width).round()),
        height: max(1, (raster.height * newSize.height / currentSize.height).round()),
      ),
    );
  }

  void _transformAllStrokes(
    Offset Function(Offset point) transformPoint, {
    double? brushSizeScale,
    required String label,
  }) {
    for (final layer in layers) {
      layer.history.commitStrokes(label, [
        for (final stroke in layer.history.strokes)
          transformStroke(
            stroke,
            transformPoint,
            brushSize: brushSizeScale == null
                ? null
                : scaleBrushSize(
                    stroke.brushSize,
                    brushSizeScale,
                    brushSizeScale,
                  ),
          ),
      ]);
    }
  }
}
