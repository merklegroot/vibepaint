import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';

/// HTTP client for a local or tunneled Ollama instance.
class OllamaClient {
  OllamaClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String baseUrl, String path) =>
      Uri.parse('${AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl)}$path');

  /// Lists models via `GET /api/tags`.
  Future<AiEnhanceConnectionStatus> testConnection({
    required String baseUrl,
    String? model,
  }) async {
    try {
      final response = await _http
          .get(_uri(baseUrl, '/api/tags'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return AiEnhanceConnectionStatus.invalid;
      }

      if (model == null || model.trim().isEmpty) {
        return AiEnhanceConnectionStatus.valid;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return AiEnhanceConnectionStatus.valid;
      }

      final models = decoded['models'];
      if (models is! List) {
        return AiEnhanceConnectionStatus.valid;
      }

      final target = model.trim().toLowerCase();
      final found = models.any((entry) {
        if (entry is! Map<String, dynamic>) {
          return false;
        }
        final name = entry['name']?.toString().toLowerCase() ?? '';
        return name == target || name.startsWith('$target:');
      });

      return found
          ? AiEnhanceConnectionStatus.valid
          : AiEnhanceConnectionStatus.invalid;
    } on Exception {
      return AiEnhanceConnectionStatus.networkError;
    }
  }

  /// Sends a sketch to Ollama and returns an enhanced image when the model supports it.
  Future<AiEnhanceResult> enhanceSketch({
    required String baseUrl,
    required String model,
    required Uint8List sourcePng,
    required String prompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) async {
    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      throw AiEnhanceException(
        'missing_model',
        'Ollama model name is not set.',
      );
    }

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Preparing sketch…',
        phase: 'prepare',
      ),
    );

    final imageB64 = base64Encode(sourcePng);

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Sending to Ollama…',
        phase: 'upload',
      ),
    );

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Generating with Ollama…',
        phase: 'generate',
      ),
    );

    Uint8List? pngBytes = await _tryGenerate(
      baseUrl: baseUrl,
      model: trimmedModel,
      prompt: prompt,
      imageB64: imageB64,
    );

    pngBytes ??= await _tryChat(
      baseUrl: baseUrl,
      model: trimmedModel,
      prompt: prompt,
      imageB64: imageB64,
    );

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Processing response…',
        phase: 'decode',
      ),
    );

    if (pngBytes == null || pngBytes.isEmpty) {
      throw AiEnhanceException(
        'text_only_model',
        'Model "$trimmedModel" returned text only. Use an image-generation '
        'model (e.g. x/flux2-klein) for sketch enhancement, or switch to Grok.',
      );
    }

    final image = img.decodeImage(pngBytes);
    if (image == null) {
      throw AiEnhanceException(
        'decode_failed',
        'Could not decode the image returned by Ollama.',
      );
    }

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Enhancement complete.',
        phase: 'done',
      ),
    );

    return AiEnhanceResult(
      pngBytes: pngBytes,
      width: image.width,
      height: image.height,
    );
  }

  Future<Uint8List?> _tryGenerate({
    required String baseUrl,
    required String model,
    required String prompt,
    required String imageB64,
  }) async {
    final response = await _http
        .post(
          _uri(baseUrl, '/api/generate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'prompt': prompt,
            'images': [imageB64],
            'stream': false,
          }),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiEnhanceException(
        'api_error',
        'Ollama request failed (${response.statusCode}).',
        details: response.body,
      );
    }

    return _extractImageBytes(response.body);
  }

  Future<Uint8List?> _tryChat({
    required String baseUrl,
    required String model,
    required String prompt,
    required String imageB64,
  }) async {
    final response = await _http
        .post(
          _uri(baseUrl, '/api/chat'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content': prompt,
                'images': [imageB64],
              },
            ],
            'stream': false,
          }),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiEnhanceException(
        'api_error',
        'Ollama chat request failed (${response.statusCode}).',
        details: response.body,
      );
    }

    return _extractImageBytes(response.body);
  }

  Uint8List? _extractImageBytes(String body) {
    for (final line in body.split('\n').reversed) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final bytes = _imageBytesFromJson(trimmed);
      if (bytes != null) {
        return bytes;
      }
    }
    return _imageBytesFromJson(body.trim());
  }

  Uint8List? _imageBytesFromJson(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final direct = decoded['image'];
    if (direct is String && direct.isNotEmpty) {
      return _decodeBase64Image(direct);
    }

    final images = decoded['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) {
        return _decodeBase64Image(first);
      }
    }

    final message = decoded['message'];
    if (message is Map<String, dynamic>) {
      final messageImages = message['images'];
      if (messageImages is List && messageImages.isNotEmpty) {
        final first = messageImages.first;
        if (first is String && first.isNotEmpty) {
          return _decodeBase64Image(first);
        }
      }
      final contentImage = message['image'];
      if (contentImage is String && contentImage.isNotEmpty) {
        return _decodeBase64Image(contentImage);
      }
    }

    return null;
  }

  Uint8List? _decodeBase64Image(String value) {
    var payload = value.trim();
    final comma = payload.indexOf(',');
    if (payload.startsWith('data:') && comma >= 0) {
      payload = payload.substring(comma + 1);
    }
    try {
      return Uint8List.fromList(base64Decode(payload));
    } on FormatException {
      return null;
    }
  }
}
