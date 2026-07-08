import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';

const _providerKey = 'ai_enhance_provider';
const _grokApiKeyKey = 'grok_api_key';
const _ollamaBaseUrlKey = 'ollama_base_url';
const _ollamaModelKey = 'ollama_model';

/// Persists AI Enhance settings (API keys stored securely).
class AiEnhanceSettingsStorage {
  AiEnhanceSettingsStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
            mOptions: const MacOsOptions(
              useDataProtectionKeyChain: false,
            ),
            wOptions: WindowsOptions(),
            lOptions: LinuxOptions(),
          );

  final FlutterSecureStorage _storage;

  Future<AiEnhanceSettings> read() async {
    final values = await Future.wait([
      _storage.read(key: _providerKey),
      _storage.read(key: _grokApiKeyKey),
      _storage.read(key: _ollamaBaseUrlKey),
      _storage.read(key: _ollamaModelKey),
    ]);

    return AiEnhanceSettings(
      activeProvider: _parseProvider(values[0]),
      grokApiKey: values[1] ?? '',
      ollamaBaseUrl: AiEnhanceSettingsStorage.normalizeBaseUrl(
        values[2] ?? AiEnhanceSettings.defaultOllamaBaseUrl,
      ),
      ollamaModel: (values[3] ?? AiEnhanceSettings.defaultOllamaModel).trim(),
    );
  }

  Future<void> write(AiEnhanceSettings settings) async {
    await Future.wait([
      _storage.write(key: _providerKey, value: settings.activeProvider.name),
      _writeOrDelete(_grokApiKeyKey, settings.grokApiKey),
      _storage.write(
        key: _ollamaBaseUrlKey,
        value: AiEnhanceSettingsStorage.normalizeBaseUrl(settings.ollamaBaseUrl),
      ),
      _storage.write(
        key: _ollamaModelKey,
        value: settings.ollamaModel.trim(),
      ),
    ]);
  }

  Future<void> _writeOrDelete(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: trimmed);
    }
  }

  AiEnhanceProviderId _parseProvider(String? raw) {
    return AiEnhanceProviderId.values.firstWhere(
      (id) => id.name == raw,
      orElse: () => AiEnhanceProviderId.grok,
    );
  }

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.isEmpty
        ? AiEnhanceSettings.defaultOllamaBaseUrl
        : normalized;
  }
}
