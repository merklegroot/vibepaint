import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// Opens the AI Enhance settings dialog (Grok API key).
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
  final _scrollController = ScrollController();
  final _statusKey = GlobalKey();
  final _grokKeyController = TextEditingController();
  final _obscureGrokKey = ValueNotifier<bool>(true);

  bool _loading = true;
  bool _busy = false;
  AiEnhanceConnectionResult? _status;
  bool _copiedStatus = false;

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
      _grokKeyController.text = settings.grokApiKey;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _grokKeyController.dispose();
    _obscureGrokKey.dispose();
    super.dispose();
  }

  AiEnhanceSettings _currentSettings() {
    return AiEnhanceSettings(grokApiKey: _grokKeyController.text);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await _service.saveSettings(_currentSettings());
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Grok API key saved.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await _service.testConnection(_currentSettings());
      if (!mounted) {
        return;
      }
      setState(() => _status = result);

      if (!result.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) {
        return;
      }
      final statusContext = _statusKey.currentContext;
      if (statusContext != null && statusContext.mounted) {
        await Scrollable.ensureVisible(
          statusContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copyStatus(AiEnhanceConnectionResult result) async {
    await Clipboard.setData(ClipboardData(text: result.copyableText));
    if (!mounted) {
      return;
    }
    setState(() => _copiedStatus = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copiedStatus = false);
    }
  }

  String _statusLabel(AiEnhanceConnectionStatus status) {
    return switch (status) {
      AiEnhanceConnectionStatus.valid => 'Connected',
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

  Widget _statusPanel(AiEnhanceConnectionResult result) {
    final color = _statusColor(result.status);
    final headline = result.message?.trim().isNotEmpty == true
        ? result.message!.trim()
        : _statusLabel(result.status);
    final details = result.details?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.workspace,
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.isValid ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(
                    color: AppColors.statusText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy message',
                onPressed: () => _copyStatus(result),
                icon: Icon(
                  _copiedStatus ? Icons.check : Icons.copy,
                  size: 18,
                ),
                color: AppColors.paletteLabel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              details,
              style: const TextStyle(
                color: AppColors.paletteLabel,
                fontFamily: 'Menlo',
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
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
        width: 480,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Grok uses the xAI cloud API to enhance sketches into '
                      'finished images. Your API key is stored securely on '
                      'this device.',
                      style: TextStyle(
                        color: AppColors.paletteLabel,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                obscure ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.paletteLabel,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.statusText,
                            fontFamily: 'Menlo',
                            fontSize: 12,
                          ),
                          onChanged: (_) => setState(() => _status = null),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _testConnection,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Test connection'),
                      ),
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 8),
                      KeyedSubtree(
                        key: _statusKey,
                        child: _statusPanel(_status!),
                      ),
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
