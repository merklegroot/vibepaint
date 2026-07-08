import 'dart:typed_data';

import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';
import 'package:vibepaint/services/ai_enhance/grok_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ollama_client.dart';
import 'package:vibepaint/services/ai_enhance/ollama_enhance_provider.dart';

/// Routes AI Enhance requests to the configured provider.
class AiEnhanceService {
  AiEnhanceService({
    AiEnhanceSettingsStorage? storage,
    List<AiEnhanceProvider>? providers,
  }) : _storage = storage ?? AiEnhanceSettingsStorage(),
       _providers = providers ??
           [GrokEnhanceProvider(), OllamaEnhanceProvider()];

  final AiEnhanceSettingsStorage _storage;
  final List<AiEnhanceProvider> _providers;

  Future<AiEnhanceSettings> loadSettings() => _storage.read();

  Future<void> saveSettings(AiEnhanceSettings settings) =>
      _storage.write(settings);

  AiEnhanceProvider providerFor(AiEnhanceSettings settings) {
    return _providers.firstWhere(
      (provider) => provider.id == settings.activeProvider,
      orElse: () => _providers.first,
    );
  }

  Future<bool> isConfigured() async {
    final settings = await loadSettings();
    return providerFor(settings).isConfigured(settings);
  }

  Future<String> missingConfigurationMessage() async {
    final settings = await loadSettings();
    return providerFor(settings).missingConfigurationMessage(settings);
  }

  Future<AiEnhanceConnectionResult> testConnection({
    required AiEnhanceProviderId providerId,
    required AiEnhanceSettings settings,
  }) {
    final provider = _providers.firstWhere(
      (entry) => entry.id == providerId,
      orElse: () => _providers.first,
    );
    return provider.testConnection(settings);
  }

  Future<void> pullOllamaModel({
    required String baseUrl,
    void Function(OllamaPullProgress progress)? onProgress,
  }) async {
    final settings = AiEnhanceSettings(ollamaBaseUrl: baseUrl);
    final provider = _providers.firstWhere(
      (entry) => entry.id == AiEnhanceProviderId.ollama,
    ) as OllamaEnhanceProvider;

    try {
      await provider.pullModel(settings: settings, onProgress: onProgress);
    } on AiEnhanceException {
      rethrow;
    } on Exception catch (error) {
      throw AiEnhanceException(
        'network_error',
        'Could not reach Ollama.',
        details: error.toString(),
      );
    }
  }

  Future<AiEnhanceResult> enhanceSketch({
    required Uint8List sourcePng,
    String prompt = defaultAiEnhancePrompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) async {
    final settings = await loadSettings();
    final provider = providerFor(settings);

    if (!provider.isConfigured(settings)) {
      throw AiEnhanceException(
        'not_configured',
        provider.missingConfigurationMessage(settings),
      );
    }

    try {
      return await provider.enhanceSketch(
        settings: settings,
        sourcePng: sourcePng,
        prompt: prompt,
        onProgress: onProgress,
      );
    } on AiEnhanceException {
      rethrow;
    } on Exception catch (error) {
      throw AiEnhanceException(
        'network_error',
        'Could not reach ${provider.displayName}.',
        details: error.toString(),
      );
    }
  }
}
