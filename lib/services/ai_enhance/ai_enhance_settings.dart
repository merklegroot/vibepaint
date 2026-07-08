/// Persisted AI Enhance configuration.
class AiEnhanceSettings {
  const AiEnhanceSettings({this.grokApiKey = ''});

  final String grokApiKey;

  AiEnhanceSettings copyWith({String? grokApiKey}) {
    return AiEnhanceSettings(grokApiKey: grokApiKey ?? this.grokApiKey);
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

  factory AiEnhanceConnectionResult.valid({String? message, String? details}) {
    return AiEnhanceConnectionResult(
      status: AiEnhanceConnectionStatus.valid,
      message: message,
      details: details,
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
