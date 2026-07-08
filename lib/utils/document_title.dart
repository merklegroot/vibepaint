import 'package:vibepaint/utils/app_version.dart';
import 'package:vibepaint/utils/canvas_file_dialogs.dart';

const appWindowTitle = 'VibePaint';
const untitledDocumentLabel = 'Untitled';
const localBuildSuffix = ' (Local build)';

String documentDisplayName(String? path) {
  if (path == null) {
    return untitledDocumentLabel;
  }
  return fileNameFromPath(path);
}

String get appWindowTitleWithVersion {
  final version = appVersion;
  final base = (version == null || version.isEmpty)
      ? appWindowTitle
      : '$appWindowTitle $version';
  if (!showLocalBuildLabel) {
    return base;
  }
  return '$base$localBuildSuffix';
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
