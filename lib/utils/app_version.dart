import 'package:package_info_plus/package_info_plus.dart';

/// Set in the GitHub release workflow so packaged binaries omit "(Local build)".
const kIsReleaseDistribution = bool.fromEnvironment('VIBE_RELEASE_BUILD');

/// Cached marketing version from pubspec / platform metadata (e.g. `1.0.2`).
String? _appVersion;

/// Test override: `null` uses [kIsReleaseDistribution], otherwise forces the label on/off.
bool? _debugShowLocalBuildLabel;

String? get appVersion => _appVersion;

bool get showLocalBuildLabel =>
    _debugShowLocalBuildLabel ?? !kIsReleaseDistribution;

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

/// Test-only hook.
void debugSetShowLocalBuildLabel(bool? show) {
  _debugShowLocalBuildLabel = show;
}
