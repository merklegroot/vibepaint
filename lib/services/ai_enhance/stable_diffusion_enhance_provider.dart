import 'dart:typed_data';

import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/stable_diffusion_client.dart';

/// Stable Diffusion WebUI (local or SSH-tunneled) AI Enhance provider.
class StableDiffusionEnhanceProvider implements AiEnhanceProvider {
  StableDiffusionEnhanceProvider({StableDiffusionClient? client})
    : _client = client ?? StableDiffusionClient();

  final StableDiffusionClient _client;

  @override
  AiEnhanceProviderId get id => AiEnhanceProviderId.stableDiffusion;

  @override
  String get displayName => 'Stable Diffusion';

  @override
  bool isConfigured(AiEnhanceSettings settings) =>
      settings.stableDiffusionBaseUrl.trim().isNotEmpty;

  @override
  String missingConfigurationMessage(AiEnhanceSettings settings) =>
      'Stable Diffusion base URL is required. Open Settings to configure.';

  @override
  Future<AiEnhanceConnectionResult> testConnection(
    AiEnhanceSettings settings,
  ) {
    return _client.testConnection(
      baseUrl: settings.stableDiffusionBaseUrl,
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
      baseUrl: settings.stableDiffusionBaseUrl,
      sourcePng: sourcePng,
      prompt: prompt,
      onProgress: onProgress,
    );
  }
}
