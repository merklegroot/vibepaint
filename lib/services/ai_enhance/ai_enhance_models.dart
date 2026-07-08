import 'dart:typed_data';

/// Default prompt for AI sketch enhancement.
const defaultAiEnhancePrompt =
    'Enhance this sketch into a clean, vibrant, professional illustration';

/// Live status updates during AI image editing.
class AiEnhanceProgress {
  const AiEnhanceProgress({
    required this.message,
    this.phase = 'working',
    this.bytesDone,
    this.bytesTotal,
    this.elapsedSeconds = 0,
  });

  final String message;
  final String phase;
  final int? bytesDone;
  final int? bytesTotal;
  final int elapsedSeconds;

  double? get progressFraction {
    if (bytesDone == null || bytesTotal == null || bytesTotal! <= 0) {
      return null;
    }
    return (bytesDone! / bytesTotal!).clamp(0.0, 1.0);
  }
}

class AiEnhanceResult {
  const AiEnhanceResult({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;
}

class AiEnhanceException implements Exception {
  AiEnhanceException(this.code, this.message, {this.details});

  final String code;
  final String message;
  final String? details;

  @override
  String toString() {
    final detail = details?.trim();
    if (detail == null || detail.isEmpty) {
      return message;
    }
    return '$message\n$detail';
  }
}
