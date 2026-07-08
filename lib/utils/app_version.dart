import 'package:package_info_plus/package_info_plus.dart';

/// Cached marketing version from pubspec / platform metadata (e.g. `1.0.2`).
String? _appVersion;

String? get appVersion => _appVersion;

Future<void> ensureAppVersionLoaded() async {
  if (_appVersion != null) {
    return;
  }

  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isNotEmpty) {
      _appVersion = version;
    }
  } on Object {
    // Widget tests and other environments may not provide package metadata.
  }
}

/// Test-only hook.
void debugSetAppVersion(String? version) {
  _appVersion = version;
}
