import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';

const _providerKey = 'ai_enhance_provider';
const _grokApiKeyKey = 'grok_api_key';
const _stableDiffusionBaseUrlKey = 'stable_diffusion_base_url';

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
            mOptions: MacOsOptions(
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
      _storage.read(key: _stableDiffusionBaseUrlKey),
    ]);

    return AiEnhanceSettings(
      activeProvider: _parseProvider(values[0]),
      grokApiKey: values[1] ?? '',
      stableDiffusionBaseUrl: normalizeBaseUrl(
        values[2] ?? AiEnhanceSettings.defaultStableDiffusionBaseUrl,
      ),
    );
  }

  Future<void> write(AiEnhanceSettings settings) async {
    await Future.wait([
      _storage.write(key: _providerKey, value: settings.activeProvider.name),
      _writeOrDelete(_grokApiKeyKey, settings.grokApiKey),
      _storage.write(
        key: _stableDiffusionBaseUrlKey,
        value: normalizeBaseUrl(settings.stableDiffusionBaseUrl),
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
        ? AiEnhanceSettings.defaultStableDiffusionBaseUrl
        : normalized;
  }
}
