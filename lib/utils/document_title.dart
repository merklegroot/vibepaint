import 'package:vibepaint/utils/canvas_file_dialogs.dart';

const appWindowTitle = 'VibePaint';
const untitledDocumentLabel = 'Untitled';

String documentDisplayName(String? path) {
  if (path == null) {
    return untitledDocumentLabel;
  }
  return fileNameFromPath(path);
}

/// Formats the native window title using the common `*Name - App` pattern.
String formatWindowTitle({
  required String documentName,
  required bool isDirty,
}) {
  final prefix = isDirty ? '*' : '';
  return '$prefix$documentName - $appWindowTitle';
}

String formatDocumentTitle({
  required String? documentPath,
  required bool isDirty,
}) {
  return formatWindowTitle(
    documentName: documentDisplayName(documentPath),
    isDirty: isDirty,
  );
}
