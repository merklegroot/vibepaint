import 'package:vibepaint/utils/app_version.dart';
import 'package:vibepaint/utils/canvas_file_dialogs.dart';

const appWindowTitle = 'VibePaint';
const untitledDocumentLabel = 'Untitled';

String documentDisplayName(String? path) {
  if (path == null) {
    return untitledDocumentLabel;
  }
  return fileNameFromPath(path);
}

String get appWindowTitleWithVersion {
  final version = appVersion;
  if (version == null || version.isEmpty) {
    return appWindowTitle;
  }
  return '$appWindowTitle $version';
}

/// Formats the native window title using the common `*Name - App` pattern.
String formatWindowTitle({
  required String documentName,
  required bool isDirty,
}) {
  final prefix = isDirty ? '*' : '';
  return '$prefix$documentName - $appWindowTitleWithVersion';
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
