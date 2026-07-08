import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';
import 'package:vibepaint/services/ai_enhance/ollama_model_utils.dart';

/// Progress update while pulling an Ollama model.
class OllamaPullProgress {
  const OllamaPullProgress({
    required this.status,
    this.completed,
    this.total,
  });

  final String status;
  final int? completed;
  final int? total;

  double? get fraction {
    final done = completed;
    final expected = total;
    if (done == null || expected == null || expected <= 0) {
      return null;
    }
    return done / expected;
  }

  String get message {
    final fraction = this.fraction;
    if (fraction != null) {
      final percent = (fraction * 100).clamp(0, 100).toStringAsFixed(1);
      return '$status ($percent%)';
    }
    return status;
  }
}

/// HTTP client for a local or tunneled Ollama instance.
class OllamaClient {
  OllamaClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String baseUrl, String path) =>
      Uri.parse('${AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl)}$path');

  /// Verifies Ollama is reachable (same approach as the Ollama app's health check).
  Future<AiEnhanceConnectionResult> testConnection({
    required String baseUrl,
    String model = AiEnhanceSettings.ollamaEnhanceModel,
  }) async {
    final normalizedUrl = AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl);

    try {
      final version = await _fetchOllamaVersion(normalizedUrl);
      if (version == null) {
        final tagsResponse = await _http
            .get(_uri(normalizedUrl, '/api/tags'))
            .timeout(const Duration(seconds: 15));

        if (tagsResponse.statusCode != 200) {
          return AiEnhanceConnectionResult.invalid(
            message: 'Ollama returned HTTP ${tagsResponse.statusCode}.',
            details: _truncate(tagsResponse.body),
          );
        }

        return AiEnhanceConnectionResult.valid(
          message: 'Connected to $normalizedUrl',
        );
      }

      final modelName = model.trim();
      if (modelName.isEmpty) {
        return AiEnhanceConnectionResult.valid(
          message: 'Connected to Ollama $version at $normalizedUrl',
        );
      }

      if (await _probeModelExists(baseUrl: normalizedUrl, model: modelName)) {
        return AiEnhanceConnectionResult.valid(
          message:
              'Connected to Ollama $version. Model "$modelName" is ready.',
        );
      }

      var available = <String>[];
      try {
        final tagsResponse = await _http
            .get(_uri(normalizedUrl, '/api/tags'))
            .timeout(const Duration(seconds: 15));
        if (tagsResponse.statusCode == 200) {
          available = parseOllamaModelNames(tagsResponse.body);
        }
      } on Exception {
        // Optional listing check.
      }

      if (available.isEmpty) {
        available = await _listModelsFromOpenAiEndpoint(normalizedUrl);
      }

      if (ollamaHasModel(available, modelName)) {
        return AiEnhanceConnectionResult.valid(
          message:
              'Connected to Ollama $version. Model "$modelName" is ready.',
        );
      }

      return AiEnhanceConnectionResult.valid(
        message: 'Connected to Ollama $version at $normalizedUrl',
        details:
            'Ollama is reachable. Model "$modelName" was not confirmed via '
            '/api/tags or /api/show, but will still be used when you run '
            'AI Enhance.\n\n'
            'If enhance fails, try Pull model or verify the model on the '
            'server with:\n'
            '  ollama run $modelName "test"',
      );
    } on http.ClientException catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach Ollama at $normalizedUrl.',
        details: error.message,
      );
    } on Exception catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach Ollama at $normalizedUrl.',
        details: error.toString(),
      );
    }
  }

  Future<List<String>> _listModelsFromOpenAiEndpoint(String baseUrl) async {
    try {
      final response = await _http
          .get(_uri(baseUrl, '/v1/models'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return const [];
      }
      return parseOpenAiModelNames(response.body);
    } on Exception {
      return const [];
    }
  }

  Future<bool> _probeModelExists({
    required String baseUrl,
    required String model,
  }) async {
    for (final candidate in ollamaModelProbeCandidates(model)) {
      for (final field in const ['model', 'name']) {
        try {
          final response = await _http
              .post(
                _uri(baseUrl, '/api/show'),
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode({field: candidate}),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            return true;
          }
        } on Exception {
          continue;
        }
      }
    }
    return false;
  }

  Future<String?> _fetchOllamaVersion(String baseUrl) async {
    try {
      final response = await _http
          .get(_uri(baseUrl, '/api/version'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final version = decoded['version']?.toString().trim();
        if (version != null && version.isNotEmpty) {
          return version;
        }
      }
    } on Exception {
      return null;
    }
    return null;
  }

  String _truncate(String value, {int maxLength = 280}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength)}…';
  }

  /// Downloads a model via `POST /api/pull` (streaming progress).
  Future<void> pullModel({
    required String baseUrl,
    String model = AiEnhanceSettings.ollamaEnhanceModel,
    void Function(OllamaPullProgress progress)? onProgress,
  }) async {
    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      throw AiEnhanceException(
        'missing_model',
        'Ollama model name is not set.',
      );
    }

    final normalizedUrl = AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl);
    final request = http.Request('POST', _uri(normalizedUrl, '/api/pull'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': trimmedModel,
        'stream': true,
      });

    onProgress?.call(
      const OllamaPullProgress(status: 'Connecting to Ollama…'),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(const Duration(seconds: 30));
    } on http.ClientException catch (error) {
      throw AiEnhanceException(
        'network_error',
        'Could not reach Ollama at $normalizedUrl.',
        details: error.message,
      );
    } on Exception catch (error) {
      throw AiEnhanceException(
        'network_error',
        'Could not reach Ollama at $normalizedUrl.',
        details: error.toString(),
      );
    }

    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw AiEnhanceException(
        'pull_failed',
        'Ollama pull failed (HTTP ${streamed.statusCode}).',
        details: _truncate(body),
      );
    }

    var buffer = '';
    var succeeded = false;
    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final newline = buffer.indexOf('\n');
        if (newline < 0) {
          break;
        }
        final line = buffer.substring(0, newline).trim();
        buffer = buffer.substring(newline + 1);
        if (line.isEmpty) {
          continue;
        }
        if (_handlePullLine(line, onProgress)) {
          succeeded = true;
        }
      }
    }

    final remaining = buffer.trim();
    if (remaining.isNotEmpty && _handlePullLine(remaining, onProgress)) {
      succeeded = true;
    }

    if (!succeeded) {
      throw AiEnhanceException(
        'pull_failed',
        'Ollama pull did not complete successfully.',
      );
    }
  }

  /// Returns true when the pull finished with `status: success`.
  bool _handlePullLine(
    String line,
    void Function(OllamaPullProgress progress)? onProgress,
  ) {
    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(line);
      if (parsed is! Map<String, dynamic>) {
        return false;
      }
      decoded = parsed;
    } on FormatException {
      return false;
    }

    final status = decoded['status']?.toString() ?? '';
    final completed = decoded['completed'];
    final total = decoded['total'];

    onProgress?.call(
      OllamaPullProgress(
        status: status.isEmpty ? 'Downloading…' : status,
        completed: completed is num ? completed.toInt() : null,
        total: total is num ? total.toInt() : null,
      ),
    );

    final error = decoded['error']?.toString();
    if (error != null && error.isNotEmpty) {
      throw AiEnhanceException(
        'pull_failed',
        'Ollama pull failed.',
        details: error,
      );
    }

    if (status == 'error') {
      throw AiEnhanceException(
        'pull_failed',
        'Ollama pull failed.',
        details: decoded['status']?.toString(),
      );
    }

    return status == 'success';
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
        'Model "$trimmedModel" returned text only, not an image. '
        'Use an image-generation model or switch to Grok.',
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
