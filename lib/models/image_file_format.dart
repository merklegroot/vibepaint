import 'dart:io';

enum ImageFileFormat {
  png,
  jpeg,
  bmp,
  gif,
  webp,
  ora,
}

extension ImageFileFormatDetails on ImageFileFormat {
  String get defaultExtension => switch (this) {
        ImageFileFormat.png => 'png',
        ImageFileFormat.jpeg => 'jpg',
        ImageFileFormat.bmp => 'bmp',
        ImageFileFormat.gif => 'gif',
        ImageFileFormat.webp => 'webp',
        ImageFileFormat.ora => 'ora',
      };

  List<String> get extensions => switch (this) {
        ImageFileFormat.jpeg => ['jpg', 'jpeg'],
        ImageFileFormat.png => ['png'],
        ImageFileFormat.bmp => ['bmp'],
        ImageFileFormat.gif => ['gif'],
        ImageFileFormat.webp => ['webp'],
        ImageFileFormat.ora => ['ora'],
      };

  String get menuLabel => switch (this) {
        ImageFileFormat.png => 'PNG (*.png)',
        ImageFileFormat.jpeg => 'JPEG (*.jpg)',
        ImageFileFormat.bmp => 'BMP (*.bmp)',
        ImageFileFormat.gif => 'GIF (*.gif)',
        ImageFileFormat.webp => 'WebP (*.webp)',
        ImageFileFormat.ora => 'OpenRaster (*.ora)',
      };

  String get description => switch (this) {
        ImageFileFormat.png => 'Lossless, supports transparency',
        ImageFileFormat.jpeg => 'Compressed, no transparency',
        ImageFileFormat.bmp => 'Uncompressed bitmap',
        ImageFileFormat.gif => 'Indexed color image',
        ImageFileFormat.webp => 'Modern compressed image',
        ImageFileFormat.ora => 'Layered image, preserves layers',
      };

  bool get isLayered => this == ImageFileFormat.ora;
}

const defaultImageFileName = 'Untitled.png';

const saveImageExtensions = [
  'png',
  'jpg',
  'jpeg',
  'bmp',
  'gif',
  'webp',
  'ora',
];

const openImageExtensions = saveImageExtensions;

ImageFileFormat? imageFormatFromExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'png':
      return ImageFileFormat.png;
    case 'jpg':
    case 'jpeg':
      return ImageFileFormat.jpeg;
    case 'bmp':
      return ImageFileFormat.bmp;
    case 'gif':
      return ImageFileFormat.gif;
    case 'webp':
      return ImageFileFormat.webp;
    case 'ora':
      return ImageFileFormat.ora;
    default:
      return null;
  }
}

ImageFileFormat? imageFormatFromPath(String path) {
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == path.length - 1) {
    return null;
  }

  return imageFormatFromExtension(path.substring(dotIndex + 1));
}

String normalizeImagePath(String path, ImageFileFormat format) {
  final lowerPath = path.toLowerCase();
  for (final extension in format.extensions) {
    if (lowerPath.endsWith('.$extension')) {
      return path;
    }
  }

  return '$path.${format.defaultExtension}';
}

String fileNameStemFromPath(String path) {
  final name = fileNameFromPath(path);
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0) {
    return name;
  }
  return name.substring(0, dotIndex);
}

String defaultSaveFileName({
  required String? documentPath,
  required ImageFileFormat format,
}) {
  final stem = documentPath == null
      ? 'Untitled'
      : fileNameStemFromPath(documentPath);
  return '$stem.${format.defaultExtension}';
}

String fileNameFromPath(String path) {
  final separator = path.lastIndexOf(Platform.pathSeparator);
  if (separator == -1) {
    return path;
  }
  return path.substring(separator + 1);
}
