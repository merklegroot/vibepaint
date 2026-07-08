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
  });

  static const defaultOllamaBaseUrl = 'http://localhost:11434';

  /// Fixed Ollama image model for AI Enhance.
  static const ollamaEnhanceModel = 'x/flux2-klein';

  final AiEnhanceProviderId activeProvider;
  final String grokApiKey;
  final String ollamaBaseUrl;

  String get activeProviderLabel => switch (activeProvider) {
    AiEnhanceProviderId.grok => 'Grok',
    AiEnhanceProviderId.ollama => 'Ollama',
  };

  AiEnhanceSettings copyWith({
    AiEnhanceProviderId? activeProvider,
    String? grokApiKey,
    String? ollamaBaseUrl,
  }) {
    return AiEnhanceSettings(
      activeProvider: activeProvider ?? this.activeProvider,
      grokApiKey: grokApiKey ?? this.grokApiKey,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
    );
  }
}

/// Result of a provider connection test.
enum AiEnhanceConnectionStatus {
  valid,
  invalid,
  networkError,
}

/// Detailed outcome from testing a provider connection.
class AiEnhanceConnectionResult {
  const AiEnhanceConnectionResult({
    required this.status,
    this.message,
    this.details,
  });

  final AiEnhanceConnectionStatus status;
  final String? message;
  final String? details;

  bool get isValid => status == AiEnhanceConnectionStatus.valid;

  /// Full message for clipboard copy (headline + details).
  String get copyableText {
    final primary = message?.trim();
    final extra = details?.trim();
    if (primary != null &&
        primary.isNotEmpty &&
        extra != null &&
        extra.isNotEmpty) {
      return '$primary\n\n$extra';
    }
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }
    if (extra != null && extra.isNotEmpty) {
      return extra;
    }
    return summary;
  }

  /// Single-line summary for UI and snackbars.
  String get summary {
    final primary = message?.trim();
    if (primary != null && primary.isNotEmpty) {
      final extra = details?.trim();
      if (extra != null && extra.isNotEmpty) {
        return '$primary $extra';
      }
      return primary;
    }
    return switch (status) {
      AiEnhanceConnectionStatus.valid => 'Connected',
      AiEnhanceConnectionStatus.invalid => 'Connection test failed',
      AiEnhanceConnectionStatus.networkError => 'Network error',
    };
  }

  factory AiEnhanceConnectionResult.valid({String? message}) {
    return AiEnhanceConnectionResult(
      status: AiEnhanceConnectionStatus.valid,
      message: message,
    );
  }

  factory AiEnhanceConnectionResult.invalid({
    required String message,
    String? details,
  }) {
    return AiEnhanceConnectionResult(
      status: AiEnhanceConnectionStatus.invalid,
      message: message,
      details: details,
    );
  }

  factory AiEnhanceConnectionResult.networkError({
    required String message,
    String? details,
  }) {
    return AiEnhanceConnectionResult(
      status: AiEnhanceConnectionStatus.networkError,
      message: message,
      details: details,
    );
  }
}
