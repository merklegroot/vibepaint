import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';

const _grokApiKeyKey = 'grok_api_key';

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
    final grokApiKey = await _storage.read(key: _grokApiKeyKey);
    return AiEnhanceSettings(grokApiKey: grokApiKey ?? '');
  }

  Future<void> write(AiEnhanceSettings settings) async {
    await _writeOrDelete(_grokApiKeyKey, settings.grokApiKey);
  }

  Future<void> _writeOrDelete(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: trimmed);
    }
  }
}
