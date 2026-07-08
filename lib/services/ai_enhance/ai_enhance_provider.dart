import 'dart:typed_data';

import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';

/// Contract for an AI Enhance backend (Grok, Ollama, …).
abstract class AiEnhanceProvider {
  AiEnhanceProviderId get id;

  String get displayName;

  /// Whether the provider has enough configuration to run enhancement.
  bool isConfigured(AiEnhanceSettings settings);

  /// Human-readable message when [isConfigured] is false.
  String missingConfigurationMessage(AiEnhanceSettings settings);

  Future<AiEnhanceConnectionResult> testConnection(AiEnhanceSettings settings);

  Future<AiEnhanceResult> enhanceSketch({
    required AiEnhanceSettings settings,
    required Uint8List sourcePng,
    required String prompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  });
}
