import 'dart:typed_data';

import 'package:vibepaint/services/ai_enhance/ai_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ollama_client.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';

/// Ollama (local or SSH-tunneled) AI Enhance provider.
class OllamaEnhanceProvider implements AiEnhanceProvider {
  OllamaEnhanceProvider({OllamaClient? client})
    : _client = client ?? OllamaClient();

  final OllamaClient _client;

  @override
  AiEnhanceProviderId get id => AiEnhanceProviderId.ollama;

  @override
  String get displayName => 'Ollama';

  @override
  bool isConfigured(AiEnhanceSettings settings) =>
      settings.ollamaBaseUrl.trim().isNotEmpty &&
      settings.ollamaModel.trim().isNotEmpty;

  @override
  String missingConfigurationMessage(AiEnhanceSettings settings) =>
      'Ollama base URL and model are required. Open Settings to configure.';

  @override
  Future<AiEnhanceConnectionStatus> testConnection(
    AiEnhanceSettings settings,
  ) {
    return _client.testConnection(
      baseUrl: settings.ollamaBaseUrl,
      model: settings.ollamaModel,
    );
  }

  @override
  Future<AiEnhanceResult> enhanceSketch({
    required AiEnhanceSettings settings,
    required Uint8List sourcePng,
    required String prompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) {
    return _client.enhanceSketch(
      baseUrl: settings.ollamaBaseUrl,
      model: settings.ollamaModel,
      sourcePng: sourcePng,
      prompt: prompt,
      onProgress: onProgress,
    );
  }
}
