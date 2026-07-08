import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/native_save_dialog.dart';

export 'package:vibepaint/models/image_file_format.dart';

Future<({ui.Image image, String path})?> pickImageFile() async {
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
  final image = await decodeImageBytes(bytes);
  return (image: image, path: path);
}

Future<String?> promptSaveImagePath({
  String fileName = defaultImageFileName,
  String? initialDirectory,
}) async {
  if (supportsNativeSaveFormatPicker) {
    return showNativeSaveDialog(
      fileName: fileNameStemFromPath(fileName),
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
