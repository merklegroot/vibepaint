import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings_storage.dart';

void main() {
  group('AiEnhanceSettingsStorage', () {
    test('normalizeBaseUrl strips trailing slashes', () {
      expect(
        AiEnhanceSettingsStorage.normalizeBaseUrl('http://127.0.0.1:7860/'),
        'http://127.0.0.1:7860',
      );
    });

    test('normalizeBaseUrl falls back to default when empty', () {
      expect(
        AiEnhanceSettingsStorage.normalizeBaseUrl('   '),
        AiEnhanceSettings.defaultStableDiffusionBaseUrl,
      );
    });
  });

  group('AiEnhanceService', () {
    test('providerFor selects active provider', () {
      final service = AiEnhanceService();
      final settings = const AiEnhanceSettings(
        activeProvider: AiEnhanceProviderId.stableDiffusion,
        stableDiffusionBaseUrl: 'http://127.0.0.1:7860',
      );

      expect(
        service.providerFor(settings).id,
        AiEnhanceProviderId.stableDiffusion,
      );
    });
  });
}
