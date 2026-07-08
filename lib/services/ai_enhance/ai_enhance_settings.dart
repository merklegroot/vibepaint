/// Which backend powers AI Enhance.
enum AiEnhanceProviderId {
  grok,
  ollama,
}

/// Persisted AI Enhance configuration.
class AiEnhanceSettings {
  const AiEnhanceSettings({
    this.activeProvider = AiEnhanceProviderId.grok,
    this.grokApiKey = '',
    this.ollamaBaseUrl = defaultOllamaBaseUrl,
    this.ollamaModel = defaultOllamaModel,
  });

  static const defaultOllamaBaseUrl = 'http://localhost:11434';
  static const defaultOllamaModel = 'llava';

  final AiEnhanceProviderId activeProvider;
  final String grokApiKey;
  final String ollamaBaseUrl;
  final String ollamaModel;

  String get activeProviderLabel => switch (activeProvider) {
    AiEnhanceProviderId.grok => 'Grok',
    AiEnhanceProviderId.ollama => 'Ollama',
  };

  AiEnhanceSettings copyWith({
    AiEnhanceProviderId? activeProvider,
    String? grokApiKey,
    String? ollamaBaseUrl,
    String? ollamaModel,
  }) {
    return AiEnhanceSettings(
      activeProvider: activeProvider ?? this.activeProvider,
      grokApiKey: grokApiKey ?? this.grokApiKey,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
    );
  }
}

/// Result of a provider connection test.
enum AiEnhanceConnectionStatus {
  valid,
  invalid,
  networkError,
}
