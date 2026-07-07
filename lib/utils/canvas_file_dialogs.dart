import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

Future<ui.Image?> pickPngImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final bytes = file.bytes ?? await File(file.path!).readAsBytes();
  return decodePngBytes(bytes);
}

Future<String?> savePngFile(
  Uint8List bytes, {
  String fileName = 'vibepaint.png',
}) async {
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['png'],
  );

  if (path == null) {
    return null;
  }

  final output = path.toLowerCase().endsWith('.png') ? path : '$path.png';
  await File(output).writeAsBytes(bytes);
  return output;
}
