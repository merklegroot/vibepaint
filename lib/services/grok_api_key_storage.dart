import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storageKey = 'grok_api_key';

/// Persists the xAI Grok API key in the platform secure store.
class GrokApiKeyStorage {
  GrokApiKeyStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            mOptions: const MacOsOptions(
              useDataProtectionKeyChain: false,
            ),
            wOptions: WindowsOptions(),
            lOptions: LinuxOptions(),
          );

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _storageKey);

  Future<void> write(String apiKey) =>
      _storage.write(key: _storageKey, value: apiKey.trim());

  Future<void> delete() => _storage.delete(key: _storageKey);

  Future<bool> hasKey() async {
    final key = await read();
    return key != null && key.trim().isNotEmpty;
  }
}
