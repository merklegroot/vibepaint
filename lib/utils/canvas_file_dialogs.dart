import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vibepaint/formats/openraster/openraster_io.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/native_save_dialog.dart';

export 'package:vibepaint/models/image_file_format.dart';

class OpenedDocument {
  const OpenedDocument._({
    required this.path,
    required this.size,
    this.flatImage,
    this.layers,
  });

  factory OpenedDocument.flat({
    required ui.Image image,
    required String path,
  }) {
    return OpenedDocument._(
      path: path,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      flatImage: image,
    );
  }

  factory OpenedDocument.layered({
    required String path,
    required Size size,
    required List<PaintLayer> layers,
  }) {
    return OpenedDocument._(
      path: path,
      size: size,
      layers: layers,
    );
  }

  final String path;
  final Size size;
  final ui.Image? flatImage;
  final List<PaintLayer>? layers;

  bool get isLayered => layers != null;
}

Future<OpenedDocument?> pickDocumentFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: openImageExtensions,
    withData: true,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final path = file.path;
  if (path == null) {
    return null;
  }

  final bytes = file.bytes ?? await File(path).readAsBytes();
  if (imageFormatFromPath(path) == ImageFileFormat.ora) {
    final document = await readOpenRasterBytes(bytes);
    return OpenedDocument.layered(
      path: path,
      size: document.size,
      layers: document.layers,
    );
  }

  final image = await decodeImageBytes(bytes);
  return OpenedDocument.flat(image: image, path: path);
}

@Deprecated('Use pickDocumentFile')
Future<({ui.Image image, String path})?> pickImageFile() async {
  final picked = await pickDocumentFile();
  if (picked == null || picked.flatImage == null) {
    return null;
  }
  return (image: picked.flatImage!, path: picked.path);
}

Future<String?> promptSaveImagePath({
  String fileName = defaultImageFileName,
  String? initialDirectory,
}) async {
  if (supportsNativeSaveFormatPicker) {
    return showNativeSaveDialog(
      fileName: fileName,
      initialDirectory: initialDirectory,
    );
  }

  return FilePicker.platform.saveFile(
    dialogTitle: 'Save As',
    fileName: fileName,
    initialDirectory: initialDirectory,
    type: FileType.custom,
    allowedExtensions: saveImageExtensions,
  );
}

Future<String?> saveImageViaNativeDialog({
  required String fileName,
  required Future<Uint8List?> Function(ImageFileFormat format) encode,
  String? initialDirectory,
}) async {
  final pickedPath = await promptSaveImagePath(
    fileName: fileName,
    initialDirectory: initialDirectory,
  );
  if (pickedPath == null) {
    return null;
  }

  final format = imageFormatFromPath(pickedPath) ?? ImageFileFormat.png;
  final path = normalizeImagePath(pickedPath, format);
  final bytes = await encode(format);
  if (bytes == null) {
    return null;
  }

  await writeImageFile(path, bytes);
  return path;
}

Future<void> writeImageFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes);
}
