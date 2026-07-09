import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';
import 'package:vibepaint/formats/openraster/ora_blend_mode.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/layer_stack_adjustments.dart';

const _openRasterMimeType = 'image/openraster';
const _openRasterVersion = '0.0.6';

class OpenRasterDocument {
  const OpenRasterDocument({
    required this.size,
    required this.layers,
  });

  final Size size;
  final List<PaintLayer> layers;
}

class _OraLayerEntry {
  const _OraLayerEntry({
    required this.src,
    required this.name,
    required this.opacity,
    required this.visible,
    required this.blendMode,
    required this.offset,
  });

  final String src;
  final String name;
  final double opacity;
  final bool visible;
  final LayerBlendMode blendMode;
  final Offset offset;
}

Future<OpenRasterDocument> readOpenRasterBytes(Uint8List bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);
  final stackFile = archive.findFile('stack.xml');
  if (stackFile == null) {
    throw FormatException('OpenRaster file is missing stack.xml');
  }

  final stackXml = utf8.decode(stackFile.content);
  final document = XmlDocument.parse(stackXml);
  final imageElement = document.rootElement;
  if (imageElement.name.local != 'image') {
    throw FormatException('OpenRaster stack.xml root must be <image>');
  }

  final width = int.parse(imageElement.getAttribute('w') ?? '');
  final height = int.parse(imageElement.getAttribute('h') ?? '');
  final size = Size(width.toDouble(), height.toDouble());

  final stackElement = imageElement.getElement('stack');
  if (stackElement == null) {
    throw FormatException('OpenRaster stack.xml is missing <stack>');
  }

  final entries = <_OraLayerEntry>[];
  _collectOraLayerEntries(stackElement, entries);

  final layers = <PaintLayer>[];
  for (final entry in entries.reversed) {
    final layerFile = archive.findFile(entry.src);
    if (layerFile == null) {
      continue;
    }

    final decoded = img.decodeImage(layerFile.content);
    if (decoded == null) {
      continue;
    }

    final uiImage = await rasterImageToUiImage(decoded);
    final bounds = Rect.fromLTWH(
      entry.offset.dx,
      entry.offset.dy,
      decoded.width.toDouble(),
      decoded.height.toDouble(),
    );
    layers.add(
      PaintLayer(
        name: entry.name,
        visible: entry.visible,
        opacity: entry.opacity,
        blendMode: entry.blendMode,
        history: StrokeHistory([
          Stroke(
            color: const Color(0x00000000),
            brushSize: 0,
            shape: StrokeShape.raster,
            points: [bounds.topLeft],
            rasterImage: uiImage,
            rasterBounds: bounds,
          ),
        ]),
      ),
    );
  }

  if (layers.isEmpty) {
    layers.add(PaintLayer(name: 'Background'));
  }

  return OpenRasterDocument(size: size, layers: layers);
}

void _collectOraLayerEntries(XmlElement stack, List<_OraLayerEntry> entries) {
  for (final child in stack.childElements) {
    switch (child.name.local) {
      case 'layer':
        entries.add(_parseOraLayerEntry(child));
      case 'stack':
        _collectOraLayerEntries(child, entries);
      default:
        break;
    }
  }
}

_OraLayerEntry _parseOraLayerEntry(XmlElement layer) {
  final src = layer.getAttribute('src');
  if (src == null || src.isEmpty) {
    throw FormatException('OpenRaster layer is missing src attribute');
  }

  return _OraLayerEntry(
    src: src,
    name: layer.getAttribute('name') ?? 'Layer',
    opacity: double.tryParse(layer.getAttribute('opacity') ?? '')?.clamp(0.0, 1.0) ??
        1.0,
    visible: layerVisibilityFromOra(layer.getAttribute('visibility')),
    blendMode: layerBlendModeFromOraCompositeOp(layer.getAttribute('composite-op')),
    offset: Offset(
      double.tryParse(layer.getAttribute('x') ?? '') ?? 0,
      double.tryParse(layer.getAttribute('y') ?? '') ?? 0,
    ),
  );
}

Future<Uint8List> writeOpenRasterBytes({
  required Size size,
  required LayerStack layerStack,
}) async {
  final archive = Archive();
  final mimeBytes = utf8.encode(_openRasterMimeType);
  archive.addFile(
    ArchiveFile.noCompress('mimetype', mimeBytes.length, mimeBytes),
  );

  final exportLayers = await _collectExportLayers(
    layerStack: layerStack,
    size: size,
  );

  final layerElements = <XmlElement>[];
  for (var i = exportLayers.length - 1; i >= 0; i--) {
    final exportLayer = exportLayers[i];
    final path = 'data/layer$i.png';
    final pngBytes = Uint8List.fromList(img.encodePng(exportLayer.raster));
    archive.addFile(ArchiveFile(path, pngBytes.length, pngBytes));

    layerElements.add(
      XmlElement(
        XmlName('layer'),
        [
          XmlAttribute(XmlName('src'), path),
          XmlAttribute(XmlName('name'), exportLayer.layer.name),
          XmlAttribute(XmlName('x'), '0'),
          XmlAttribute(XmlName('y'), '0'),
          XmlAttribute(
            XmlName('opacity'),
            exportLayer.layer.opacity.toStringAsFixed(3),
          ),
          XmlAttribute(
            XmlName('visibility'),
            oraVisibilityAttribute(exportLayer.layer.visible),
          ),
          XmlAttribute(
            XmlName('composite-op'),
            oraCompositeOpFromLayerBlendMode(exportLayer.layer.blendMode),
          ),
        ],
      ),
    );
  }

  final stackElement = XmlElement(
    XmlName('stack'),
    const [],
    layerElements,
  );
  final imageElement = XmlElement(
    XmlName('image'),
    [
      XmlAttribute(XmlName('w'), size.width.ceil().toString()),
      XmlAttribute(XmlName('h'), size.height.ceil().toString()),
      XmlAttribute(XmlName('version'), _openRasterVersion),
    ],
    [stackElement],
  );
  final stackXml = '<?xml version="1.0" encoding="UTF-8"?>\n'
      '${imageElement.toXmlString(pretty: true)}';
  final stackBytes = utf8.encode(stackXml);
  archive.addFile(ArchiveFile('stack.xml', stackBytes.length, stackBytes));

  final mergedBytes = await renderCanvasToBytes(
    size: size,
    layers: layerStack.layers,
    backgroundImage: layerStack.backgroundImage,
    backgroundColor: layerStack.backgroundColor,
    format: ImageFileFormat.png,
  );
  archive.addFile(
    ArchiveFile('mergedimage.png', mergedBytes.length, mergedBytes),
  );

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _ExportLayer {
  const _ExportLayer({
    required this.layer,
    required this.raster,
  });

  final PaintLayer layer;
  final img.Image raster;
}

Future<List<_ExportLayer>> _collectExportLayers({
  required LayerStack layerStack,
  required Size size,
}) async {
  final exportLayers = <_ExportLayer>[];

  if (layerStack.backgroundImage != null) {
    final raster = await _backgroundImageRaster(
      layerStack.backgroundImage!,
      size,
    );
    if (raster != null) {
      exportLayers.add(
        _ExportLayer(
          layer: PaintLayer(name: 'Background'),
          raster: raster,
        ),
      );
    }
  } else if (!isTransparentCanvasBackground(layerStack.backgroundColor)) {
    exportLayers.add(
      _ExportLayer(
        layer: PaintLayer(name: 'Background'),
        raster: _solidColorRaster(size, layerStack.backgroundColor),
      ),
    );
  }

  for (var i = 0; i < layerStack.layers.length; i++) {
    final layer = layerStack.layers[i];
    final raster = await layerStack.captureLayerRaster(size, i) ??
        _transparentRaster(size);
    exportLayers.add(_ExportLayer(layer: layer, raster: raster));
  }

  return exportLayers;
}

Future<img.Image?> _backgroundImageRaster(ui.Image image, Size size) async {
  final raster = await uiImageToRasterImage(image);
  final width = size.width.ceil();
  final height = size.height.ceil();
  if (raster.width == width && raster.height == height) {
    return raster;
  }

  return img.copyResize(
    raster,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
}

img.Image _solidColorRaster(Size size, Color color) {
  final width = size.width.ceil();
  final height = size.height.ceil();
  final raster = img.Image(width: width, height: height, numChannels: 4);
  img.fill(
    raster,
    color: img.ColorRgba8(color.red, color.green, color.blue, color.alpha),
  );
  return raster;
}

img.Image _transparentRaster(Size size) {
  return img.Image(
    width: size.width.ceil(),
    height: size.height.ceil(),
    numChannels: 4,
  );
}
