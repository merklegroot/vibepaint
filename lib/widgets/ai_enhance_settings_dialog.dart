import 'package:flutter/material.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// Opens the AI Enhance settings dialog (provider picker + Grok/Ollama config).
Future<void> showAiEnhanceSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AiEnhanceSettingsDialog(),
  );
}

class AiEnhanceSettingsDialog extends StatefulWidget {
  const AiEnhanceSettingsDialog({super.key});

  @override
  State<AiEnhanceSettingsDialog> createState() =>
      _AiEnhanceSettingsDialogState();
}

class _AiEnhanceSettingsDialogState extends State<AiEnhanceSettingsDialog> {
  final _service = AiEnhanceService();
  final _grokKeyController = TextEditingController();
  final _ollamaUrlController = TextEditingController();
  final _ollamaModelController = TextEditingController();
  final _obscureGrokKey = ValueNotifier<bool>(true);

  bool _loading = true;
  bool _busy = false;
  AiEnhanceProviderId _activeProvider = AiEnhanceProviderId.grok;
  AiEnhanceConnectionStatus? _grokStatus;
  AiEnhanceConnectionStatus? _ollamaStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeProvider = settings.activeProvider;
      _grokKeyController.text = settings.grokApiKey;
      _ollamaUrlController.text = settings.ollamaBaseUrl;
      _ollamaModelController.text = settings.ollamaModel;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _grokKeyController.dispose();
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    _obscureGrokKey.dispose();
    super.dispose();
  }

  AiEnhanceSettings _currentSettings() {
    return AiEnhanceSettings(
      activeProvider: _activeProvider,
      grokApiKey: _grokKeyController.text,
      ollamaBaseUrl: _ollamaUrlController.text,
      ollamaModel: _ollamaModelController.text,
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await _service.saveSettings(_currentSettings());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Enhance settings saved.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testGrok() async {
    setState(() {
      _busy = true;
      _grokStatus = null;
    });
    try {
      final status = await _service.testConnection(
        providerId: AiEnhanceProviderId.grok,
        settings: _currentSettings(),
      );
      if (mounted) {
        setState(() => _grokStatus = status);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testOllama() async {
    setState(() {
      _busy = true;
      _ollamaStatus = null;
    });
    try {
      final status = await _service.testConnection(
        providerId: AiEnhanceProviderId.ollama,
        settings: _currentSettings(),
      );
      if (mounted) {
        setState(() => _ollamaStatus = status);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _statusLabel(AiEnhanceConnectionStatus status) {
    return switch (status) {
      AiEnhanceConnectionStatus.valid => 'Valid',
      AiEnhanceConnectionStatus.invalid => 'Invalid',
      AiEnhanceConnectionStatus.networkError => 'Network error',
    };
  }

  Color _statusColor(AiEnhanceConnectionStatus status) {
    return switch (status) {
      AiEnhanceConnectionStatus.valid => Colors.green.shade700,
      AiEnhanceConnectionStatus.invalid => Colors.red.shade700,
      AiEnhanceConnectionStatus.networkError => Colors.orange.shade800,
    };
  }

  Widget _statusRow(AiEnhanceConnectionStatus status) {
    return Row(
      children: [
        Icon(
          status == AiEnhanceConnectionStatus.valid
              ? Icons.check_circle
              : Icons.error_outline,
          size: 18,
          color: _statusColor(status),
        ),
        const SizedBox(width: 8),
        Text(
          'Status: ${_statusLabel(status)}',
          style: TextStyle(
            color: _statusColor(status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'AI Enhance Settings',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Default provider',
                      style: TextStyle(
                        color: AppColors.statusText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<AiEnhanceProviderId>(
                      segments: const [
                        ButtonSegment(
                          value: AiEnhanceProviderId.grok,
                          label: Text('Grok'),
                        ),
                        ButtonSegment(
                          value: AiEnhanceProviderId.ollama,
                          label: Text('Ollama'),
                        ),
                      ],
                      selected: {_activeProvider},
                      onSelectionChanged: _busy
                          ? null
                          : (selection) {
                              setState(() => _activeProvider = selection.first);
                            },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Grok (xAI cloud)',
                      style: TextStyle(
                        color: AppColors.statusText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your xAI API key. Stored securely on this device.',
                      style: TextStyle(
                        color: AppColors.paletteLabel,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: _obscureGrokKey,
                      builder: (context, obscure, _) {
                        return TextField(
                          controller: _grokKeyController,
                          obscureText: obscure,
                          enabled: !_busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Grok API key',
                            labelStyle: const TextStyle(
                              color: AppColors.paletteLabel,
                            ),
                            suffixIcon: IconButton(
                              tooltip: obscure ? 'Show key' : 'Hide key',
                              onPressed: () =>
                                  _obscureGrokKey.value = !obscure,
                              icon: Icon(
                                obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.paletteLabel,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.statusText,
                            fontFamily: 'Menlo',
                            fontSize: 12,
                          ),
                          onChanged: (_) {
                            if (_grokStatus != null) {
                              setState(() => _grokStatus = null);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _testGrok,
                        child: const Text('Test Grok Connection'),
                      ),
                    ),
                    if (_grokStatus != null) ...[
                      const SizedBox(height: 4),
                      _statusRow(_grokStatus!),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Ollama (local or SSH tunnel)',
                      style: TextStyle(
                        color: AppColors.statusText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Run an SSH tunnel on your Mac, then point at localhost:\n'
                      'ssh -L 11434:localhost:11434 user@server',
                      style: TextStyle(
                        color: AppColors.paletteLabel,
                        fontSize: 13,
                        fontFamily: 'Menlo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ollamaUrlController,
                      enabled: !_busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Ollama base URL',
                        labelStyle: TextStyle(color: AppColors.paletteLabel),
                        hintText: AiEnhanceSettings.defaultOllamaBaseUrl,
                      ),
                      style: const TextStyle(
                        color: AppColors.statusText,
                        fontFamily: 'Menlo',
                        fontSize: 12,
                      ),
                      onChanged: (_) {
                        if (_ollamaStatus != null) {
                          setState(() => _ollamaStatus = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ollamaModelController,
                      enabled: !_busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Model name',
                        labelStyle: TextStyle(color: AppColors.paletteLabel),
                        hintText: AiEnhanceSettings.defaultOllamaModel,
                        helperText:
                            'Vision: llava, moondream, bakllava. '
                            'Image output: x/flux2-klein',
                        helperStyle: TextStyle(
                          color: AppColors.paletteLabel,
                          fontSize: 11,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.statusText,
                        fontFamily: 'Menlo',
                        fontSize: 12,
                      ),
                      onChanged: (_) {
                        if (_ollamaStatus != null) {
                          setState(() => _ollamaStatus = null);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _testOllama,
                        child: const Text('Test Ollama Connection'),
                      ),
                    ),
                    if (_ollamaStatus != null) ...[
                      const SizedBox(height: 4),
                      _statusRow(_ollamaStatus!),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _busy || _loading ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
