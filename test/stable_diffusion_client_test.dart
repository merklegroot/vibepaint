import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/stable_diffusion_client.dart';

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('StableDiffusionClient', () {
    test('testConnection reports active checkpoint', () async {
      final client = StableDiffusionClient(
        httpClient: _MockHttpClient((request) async {
          if (request.url.path == '/sdapi/v1/sd-models') {
            return http.Response(
              jsonEncode([
                {'title': 'modelA.safetensors'},
                {'title': 'modelB.safetensors'},
              ]),
              200,
            );
          }
          if (request.url.path == '/sdapi/v1/options') {
            return http.Response(
              jsonEncode({'sd_model_checkpoint': 'modelA.safetensors'}),
              200,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final result = await client.testConnection(
        baseUrl: 'http://127.0.0.1:7860',
      );

      expect(result.isValid, isTrue);
      expect(result.message, contains('modelA.safetensors'));
    });

    test('testConnection surfaces HTTP errors', () async {
      final client = StableDiffusionClient(
        httpClient: _MockHttpClient((request) async {
          return http.Response('API disabled', 404);
        }),
      );

      final result = await client.testConnection(
        baseUrl: 'http://127.0.0.1:7860',
      );

      expect(result.isValid, isFalse);
      expect(result.message, contains('HTTP 404'));
    });

    test('enhanceSketch returns decoded image from img2img response', () async {
      final source = img.Image(width: 16, height: 16, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(0, 0, 0, 255));
      final sourcePng = Uint8List.fromList(img.encodePng(source));

      final output = img.Image(width: 16, height: 16, numChannels: 4);
      img.fill(output, color: img.ColorRgba8(255, 0, 0, 255));
      final outputB64 = base64Encode(img.encodePng(output));

      final client = StableDiffusionClient(
        httpClient: _MockHttpClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/sdapi/v1/img2img');

          final body = await request.finalize().bytesToString();
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          expect(decoded['prompt'], isNotEmpty);
          expect(decoded['init_images'], hasLength(1));
          expect(decoded['denoising_strength'],
              AiEnhanceSettings.stableDiffusionDenoising);

          return http.Response(jsonEncode({'images': [outputB64]}), 200);
        }),
      );

      final result = await client.enhanceSketch(
        baseUrl: 'http://127.0.0.1:7860',
        sourcePng: sourcePng,
        prompt: 'Enhance this sketch',
      );

      expect(result.width, 16);
      expect(result.height, 16);
      expect(result.pngBytes, isNotEmpty);
    });
  });
}
