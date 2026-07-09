import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';

/// HTTP client for a local or tunneled AUTOMATIC1111 Stable Diffusion WebUI.
class StableDiffusionClient {
  StableDiffusionClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String baseUrl, String path) => Uri.parse(
    '${AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl)}$path',
  );

  /// Verifies the WebUI API is reachable and reports the active checkpoint.
  Future<AiEnhanceConnectionResult> testConnection({
    required String baseUrl,
  }) async {
    final normalizedUrl = AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl);

    try {
      final modelsResponse = await _http
          .get(_uri(normalizedUrl, '/sdapi/v1/sd-models'))
          .timeout(const Duration(seconds: 15));

      if (modelsResponse.statusCode != 200) {
        return AiEnhanceConnectionResult.invalid(
          message:
              'Stable Diffusion returned HTTP ${modelsResponse.statusCode}.',
          details: _truncate(modelsResponse.body),
        );
      }

      final models = _parseModelTitles(modelsResponse.body);
      final activeModel = await _fetchActiveModel(normalizedUrl);

      if (activeModel != null) {
        return AiEnhanceConnectionResult.valid(
          message:
              'Connected to Stable Diffusion at $normalizedUrl. '
              'Model: $activeModel',
        );
      }

      if (models.isNotEmpty) {
        return AiEnhanceConnectionResult.valid(
          message: 'Connected to Stable Diffusion at $normalizedUrl.',
          details:
              '${models.length} checkpoint(s) available. '
              'The server\'s currently loaded model will be used for AI Enhance.',
        );
      }

      return AiEnhanceConnectionResult.valid(
        message: 'Connected to Stable Diffusion at $normalizedUrl.',
      );
    } on http.ClientException catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach Stable Diffusion at $normalizedUrl.',
        details: '${error.message}\n\n'
            'Ensure the WebUI is running with --api and reachable at this URL. '
            'For a remote server, use SSH port forwarding.',
      );
    } on Exception catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach Stable Diffusion at $normalizedUrl.',
        details: error.toString(),
      );
    }
  }

  Future<String?> _fetchActiveModel(String baseUrl) async {
    try {
      final response = await _http
          .get(_uri(baseUrl, '/sdapi/v1/options'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final model = decoded['sd_model_checkpoint']?.toString().trim();
      return model == null || model.isEmpty ? null : model;
    } on Exception {
      return null;
    }
  }

  List<String> _parseModelTitles(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .map((entry) {
            if (entry is Map<String, dynamic>) {
              return entry['title']?.toString().trim();
            }
            return null;
          })
          .whereType<String>()
          .where((title) => title.isNotEmpty)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  String _truncate(String value, {int maxLength = 280}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength)}…';
  }

  /// Sends a sketch to img2img and returns an enhanced image.
  Future<AiEnhanceResult> enhanceSketch({
    required String baseUrl,
    required Uint8List sourcePng,
    required String prompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) async {
    final normalizedUrl = AiEnhanceSettingsStorage.normalizeBaseUrl(baseUrl);

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Preparing sketch…',
        phase: 'prepare',
      ),
    );

    final sourceImage = img.decodePng(sourcePng);
    if (sourceImage == null) {
      throw AiEnhanceException(
        'decode_failed',
        'Could not decode the sketch image.',
      );
    }

    final width = _sdDimension(sourceImage.width);
    final height = _sdDimension(sourceImage.height);
    final imageB64 = base64Encode(sourcePng);

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Sending to Stable Diffusion…',
        phase: 'upload',
      ),
    );

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Generating with Stable Diffusion…',
        phase: 'generate',
      ),
    );

    final response = await _http
        .post(
          _uri(normalizedUrl, '/sdapi/v1/img2img'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'init_images': [imageB64],
            'prompt': prompt,
            'negative_prompt': AiEnhanceSettings.stableDiffusionNegativePrompt,
            'denoising_strength': AiEnhanceSettings.stableDiffusionDenoising,
            'cfg_scale': AiEnhanceSettings.stableDiffusionCfgScale,
            'steps': AiEnhanceSettings.stableDiffusionSteps,
            'sampler_name': AiEnhanceSettings.stableDiffusionSampler,
            'width': width,
            'height': height,
            'resize_mode': 0,
          }),
        )
        .timeout(const Duration(minutes: 5));

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Processing response…',
        phase: 'decode',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiEnhanceException(
        'api_error',
        'Stable Diffusion request failed (${response.statusCode}).',
        details: _truncate(response.body),
      );
    }

    final pngBytes = _extractImageBytes(response.body);
    if (pngBytes == null || pngBytes.isEmpty) {
      throw AiEnhanceException(
        'empty_response',
        'Stable Diffusion returned no image.',
        details: _truncate(response.body),
      );
    }

    final image = img.decodeImage(pngBytes);
    if (image == null) {
      throw AiEnhanceException(
        'decode_failed',
        'Could not decode the image returned by Stable Diffusion.',
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

  int _sdDimension(int value) {
    final clamped = value.clamp(64, 2048);
    return ((clamped + 7) ~/ 8) * 8;
  }

  Uint8List? _extractImageBytes(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final images = decoded['images'];
      if (images is! List || images.isEmpty) {
        return null;
      }
      final first = images.first;
      if (first is! String || first.isEmpty) {
        return null;
      }
      return _decodeBase64Image(first);
    } on FormatException {
      return null;
    }
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
