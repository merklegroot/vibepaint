import 'dart:typed_data';

import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_provider.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';
import 'package:vibepaint/services/ai_enhance/grok_enhance_provider.dart';

/// Routes AI Enhance requests to Grok.
class AiEnhanceService {
  AiEnhanceService({
    AiEnhanceSettingsStorage? storage,
    AiEnhanceProvider? provider,
  }) : _storage = storage ?? AiEnhanceSettingsStorage(),
       _provider = provider ?? GrokEnhanceProvider();

  final AiEnhanceSettingsStorage _storage;
  final AiEnhanceProvider _provider;

  Future<AiEnhanceSettings> loadSettings() => _storage.read();

  Future<void> saveSettings(AiEnhanceSettings settings) =>
      _storage.write(settings);

  Future<bool> isConfigured() async {
    final settings = await loadSettings();
    return _provider.isConfigured(settings);
  }

  Future<String> missingConfigurationMessage() async {
    final settings = await loadSettings();
    return _provider.missingConfigurationMessage(settings);
  }

  Future<AiEnhanceConnectionResult> testConnection(
    AiEnhanceSettings settings,
  ) {
    return _provider.testConnection(settings);
  }

  Future<AiEnhanceResult> enhanceSketch({
    required Uint8List sourcePng,
    String prompt = defaultAiEnhancePrompt,
    void Function(AiEnhanceProgress progress)? onProgress,
  }) async {
    final settings = await loadSettings();

    if (!_provider.isConfigured(settings)) {
      throw AiEnhanceException(
        'not_configured',
        _provider.missingConfigurationMessage(settings),
      );
    }

    try {
      return await _provider.enhanceSketch(
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
        'Could not reach ${_provider.displayName}.',
        details: error.toString(),
      );
    }
  }
}
