import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

const defaultPngFileName = 'Untitled.png';

Future<({ui.Image image, String path})?> pickPngImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'],
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
  final image = await decodePngBytes(bytes);
  return (image: image, path: path);
}

Future<String?> savePngFile(
  Uint8List bytes, {
  String fileName = defaultPngFileName,
}) async {
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['png'],
  );

  if (path == null) {
    return null;
  }

  await writePngFile(path, bytes);
  return normalizePngPath(path);
}

Future<void> writePngFile(String path, Uint8List bytes) async {
  await File(normalizePngPath(path)).writeAsBytes(bytes);
}

String normalizePngPath(String path) {
  return path.toLowerCase().endsWith('.png') ? path : '$path.png';
}

String fileNameFromPath(String path) {
  final separator = path.lastIndexOf(Platform.pathSeparator);
  if (separator == -1) {
    return path;
  }
  return path.substring(separator + 1);
}
