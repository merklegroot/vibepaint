import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:vibepaint/services/ai_enhance/ai_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/grok_client.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';

/// Grok (xAI cloud) AI Enhance provider.
class GrokEnhanceProvider implements AiEnhanceProvider {
  GrokEnhanceProvider({GrokClient? client}) : _client = client ?? GrokClient();

  final GrokClient _client;

  @override
  AiEnhanceProviderId get id => AiEnhanceProviderId.grok;

  @override
  String get displayName => 'Grok';

  @override
  bool isConfigured(AiEnhanceSettings settings) =>
      settings.grokApiKey.trim().isNotEmpty;

  @override
  String missingConfigurationMessage(AiEnhanceSettings settings) =>
      'Grok API key is not set. Open Settings to add your key.';

  @override
  Future<AiEnhanceConnectionStatus> testConnection(
    AiEnhanceSettings settings,
  ) async {
    final status = await _client.testConnection(settings.grokApiKey);
    return switch (status) {
      GrokConnectionStatus.valid => AiEnhanceConnectionStatus.valid,
      GrokConnectionStatus.invalid => AiEnhanceConnectionStatus.invalid,
      GrokConnectionStatus.networkError =>
        AiEnhanceConnectionStatus.networkError,
    };
  }

  @override
  Future<AiEnhanceResult> enhanceSketch({
    required AiEnhanceSettings settings,
    required Uint8List sourcePng,
    required String prompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) {
    return _client.enhanceSketch(
      apiKey: settings.grokApiKey,
      sourcePng: sourcePng,
      prompt: prompt,
      onProgress: onProgress,
    );
  }
}
