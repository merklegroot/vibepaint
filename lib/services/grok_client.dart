import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';

const grokApiBaseUrl = 'https://api.x.ai/v1';
const grokImageEditModel = 'grok-imagine-image-quality';

String _truncateGrokBody(String value, {int maxLength = 280}) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxLength)}…';
}

/// Lightweight HTTP client for xAI Grok image editing.
class GrokClient {
  GrokClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Map<String, String> _headers(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  /// Verifies the API key with a models list request (no image generation).
  Future<AiEnhanceConnectionResult> testConnection(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return AiEnhanceConnectionResult.invalid(
        message: 'Grok API key is empty.',
      );
    }

    try {
      final response = await _http
          .get(
            Uri.parse('$grokApiBaseUrl/models'),
            headers: _headers(trimmed),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return AiEnhanceConnectionResult.valid(
          message: 'Connected to xAI.',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AiEnhanceConnectionResult.invalid(
          message: 'Grok API key was rejected (HTTP ${response.statusCode}).',
          details: _truncateGrokBody(response.body),
        );
      }
      return AiEnhanceConnectionResult.invalid(
        message: 'xAI returned HTTP ${response.statusCode}.',
        details: _truncateGrokBody(response.body),
      );
    } on http.ClientException catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach xAI.',
        details: error.message,
      );
    } on Exception catch (error) {
      return AiEnhanceConnectionResult.networkError(
        message: 'Could not reach xAI.',
        details: error.toString(),
      );
    }
  }

  /// Edits a sketch PNG via Grok Imagine and returns the enhanced result.
  Future<AiEnhanceResult> enhanceSketch({
    required String apiKey,
    required Uint8List sourcePng,
    String prompt = defaultAiEnhancePrompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw AiEnhanceException('missing_api_key', 'Grok API key is not set.');
    }

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Preparing sketch…',
        phase: 'prepare',
      ),
    );

    final dataUri =
        'data:image/png;base64,${base64Encode(sourcePng)}';

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Sending to Grok…',
        phase: 'upload',
      ),
    );

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Generating with Grok…',
        phase: 'generate',
      ),
    );

    final response = await _http
        .post(
          Uri.parse('$grokApiBaseUrl/images/edits'),
          headers: _headers(trimmedKey),
          body: jsonEncode({
            'model': grokImageEditModel,
            'prompt': prompt,
            'response_format': 'b64_json',
            'image': {
              'url': dataUri,
              'type': 'image_url',
            },
          }),
        )
        .timeout(const Duration(minutes: 3));

    onProgress?.call(
      const AiEnhanceProgress(
        message: 'Processing response…',
        phase: 'decode',
      ),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AiEnhanceException(
        'invalid_api_key',
        'Grok API key was rejected. Check Settings and try again.',
        details: response.body,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiEnhanceException(
        'api_error',
        'Grok API request failed (${response.statusCode}).',
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AiEnhanceException(
        'invalid_response',
        'Unexpected response from Grok API.',
      );
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw AiEnhanceException(
        'empty_response',
        'Grok returned no images.',
        details: response.body,
      );
    }

    final first = data.first;
    if (first is! Map<String, dynamic>) {
      throw AiEnhanceException(
        'invalid_response',
        'Unexpected image payload from Grok API.',
      );
    }

    Uint8List? pngBytes;
    final b64 = first['b64_json'];
    if (b64 is String && b64.isNotEmpty) {
      pngBytes = Uint8List.fromList(base64Decode(b64));
    } else {
      final url = first['url'];
      if (url is String && url.isNotEmpty) {
        final imageResponse = await _http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 60));
        if (imageResponse.statusCode != 200) {
          throw AiEnhanceException(
            'download_failed',
            'Could not download the generated image.',
          );
        }
        pngBytes = imageResponse.bodyBytes;
      }
    }

    if (pngBytes == null || pngBytes.isEmpty) {
      throw AiEnhanceException(
        'missing_image',
        'Grok response did not include image data.',
      );
    }

    final image = img.decodeImage(pngBytes);
    if (image == null) {
      throw AiEnhanceException(
        'decode_failed',
        'Could not decode the image returned by Grok.',
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
}
