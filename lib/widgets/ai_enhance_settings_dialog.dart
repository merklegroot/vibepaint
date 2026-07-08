import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/ollama_pull_progress_dialog.dart';

/// Example SSH tunnel for reaching a remote Ollama instance.
const ollamaSshTunnelCommand =
    'ssh -L 11434:localhost:11434 user@server';

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
  final _scrollController = ScrollController();
  final _grokStatusKey = GlobalKey();
  final _ollamaStatusKey = GlobalKey();
  final _grokKeyController = TextEditingController();
  final _ollamaUrlController = TextEditingController();
  final _obscureGrokKey = ValueNotifier<bool>(true);

  bool _loading = true;
  bool _busy = false;
  AiEnhanceProviderId _activeProvider = AiEnhanceProviderId.grok;
  AiEnhanceConnectionResult? _grokStatus;
  AiEnhanceConnectionResult? _ollamaStatus;
  String? _copiedStatusPanelKey;

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
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _grokKeyController.dispose();
    _ollamaUrlController.dispose();
    _obscureGrokKey.dispose();
    super.dispose();
  }

  AiEnhanceSettings _currentSettings() {
    return AiEnhanceSettings(
      activeProvider: _activeProvider,
      grokApiKey: _grokKeyController.text,
      ollamaBaseUrl: _ollamaUrlController.text,
    );
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
          content: Text('AI Enhance settings saved.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showTestResult({
    required AiEnhanceProviderId providerId,
    required AiEnhanceConnectionResult result,
    required GlobalKey statusKey,
  }) async {
    setState(() {
      switch (providerId) {
        case AiEnhanceProviderId.grok:
          _grokStatus = result;
        case AiEnhanceProviderId.ollama:
          _ollamaStatus = result;
      }
    });

    if (!mounted) {
      return;
    }

    final summary = result.summary;
    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final statusContext = statusKey.currentContext;
    if (statusContext != null && mounted) {
      await Scrollable.ensureVisible(
        statusContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _testGrok() async {
    setState(() {
      _busy = true;
      _grokStatus = null;
    });
    try {
      final result = await _service.testConnection(
        providerId: AiEnhanceProviderId.grok,
        settings: _currentSettings(),
      );
      await _showTestResult(
        providerId: AiEnhanceProviderId.grok,
        result: result,
        statusKey: _grokStatusKey,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pullOllamaModel() async {
    setState(() => _busy = true);
    try {
      await showOllamaPullProgressDialog(
        context: context,
        work: (onProgress) => _service.pullOllamaModel(
          baseUrl: _ollamaUrlController.text,
          onProgress: onProgress,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AiEnhanceSettings.ollamaEnhanceModel} downloaded successfully.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      await _testOllama();
    } on Object {
      // Error snackbar shown by progress dialog.
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
      final result = await _service.testConnection(
        providerId: AiEnhanceProviderId.ollama,
        settings: _currentSettings(),
      );
      await _showTestResult(
        providerId: AiEnhanceProviderId.ollama,
        result: result,
        statusKey: _ollamaStatusKey,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
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

  Future<void> _copyConnectionResult(
    AiEnhanceConnectionResult result, {
    required String panelKey,
  }) async {
    await Clipboard.setData(ClipboardData(text: result.copyableText));
    if (!mounted) {
      return;
    }
    setState(() => _copiedStatusPanelKey = panelKey);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted && _copiedStatusPanelKey == panelKey) {
      setState(() => _copiedStatusPanelKey = null);
    }
  }

  Widget _statusPanel(
    AiEnhanceConnectionResult result, {
    required String panelKey,
  }) {
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
                onPressed: () => _copyConnectionResult(
                  result,
                  panelKey: panelKey,
                ),
                icon: Icon(
                  _copiedStatusPanelKey == panelKey
                      ? Icons.check
                      : Icons.copy,
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

  bool _isGrokConfigured() => _grokKeyController.text.trim().isNotEmpty;

  bool _isOllamaConfigured() => _ollamaUrlController.text.trim().isNotEmpty;

  Widget _providerPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AI provider for Enhance',
          style: TextStyle(
            color: AppColors.statusText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose which service runs when you click AI Enhance.',
          style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProviderOptionCard(
                icon: Icons.auto_awesome,
                title: 'Grok',
                subtitle: 'xAI cloud · API key',
                selected: _activeProvider == AiEnhanceProviderId.grok,
                configured: _isGrokConfigured(),
                testResult: _grokStatus,
                enabled: !_busy,
                onTap: () => setState(
                  () => _activeProvider = AiEnhanceProviderId.grok,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProviderOptionCard(
                icon: Icons.dns_outlined,
                title: 'Ollama',
                subtitle: AiEnhanceSettings.ollamaEnhanceModel,
                selected: _activeProvider == AiEnhanceProviderId.ollama,
                configured: _isOllamaConfigured(),
                testResult: _ollamaStatus,
                enabled: !_busy,
                onTap: () => setState(
                  () => _activeProvider = AiEnhanceProviderId.ollama,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _grokSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.auto_awesome,
          title: 'Grok configuration',
          subtitle: 'Requires an xAI API key, stored securely on this device.',
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
                labelStyle: const TextStyle(color: AppColors.paletteLabel),
                suffixIcon: IconButton(
                  tooltip: obscure ? 'Show key' : 'Hide key',
                  onPressed: () => _obscureGrokKey.value = !obscure,
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
              onChanged: (_) => setState(() => _grokStatus = null),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _testGrok,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Test connection'),
          ),
        ),
        if (_grokStatus != null) ...[
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _grokStatusKey,
            child: _statusPanel(_grokStatus!, panelKey: 'grok'),
          ),
        ],
      ],
    );
  }

  Widget _ollamaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.dns_outlined,
          title: 'Ollama configuration',
          subtitle: 'Connect to Ollama on this Mac or via SSH port forwarding.',
        ),
        const SizedBox(height: 12),
        const Text(
          'SSH tunnel example (run in Terminal):',
          style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _CopyableCommandRow(command: ollamaSshTunnelCommand),
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
          onChanged: (_) => setState(() => _ollamaStatus = null),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.workspace,
            border: Border.all(color: AppColors.paletteBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Model',
                style: TextStyle(
                  color: AppColors.paletteLabel,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AiEnhanceSettings.ollamaEnhanceModel,
                style: const TextStyle(
                  color: AppColors.statusText,
                  fontFamily: 'Menlo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vision model used for sketch enhancement.',
                style: TextStyle(
                  color: AppColors.paletteLabel,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _busy ? null : _testOllama,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Test connection'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _pullOllamaModel,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Pull model'),
            ),
          ],
        ),
        if (_ollamaStatus != null) ...[
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _ollamaStatusKey,
            child: _statusPanel(_ollamaStatus!, panelKey: 'ollama'),
          ),
        ],
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
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _providerPicker(),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: switch (_activeProvider) {
                        AiEnhanceProviderId.grok => KeyedSubtree(
                          key: const ValueKey('grok'),
                          child: _grokSection(),
                        ),
                        AiEnhanceProviderId.ollama => KeyedSubtree(
                          key: const ValueKey('ollama'),
                          child: _ollamaSection(),
                        ),
                      },
                    ),
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

class _ProviderOptionCard extends StatelessWidget {
  const _ProviderOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.configured,
    required this.enabled,
    required this.onTap,
    this.testResult,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool configured;
  final bool enabled;
  final VoidCallback onTap;
  final AiEnhanceConnectionResult? testResult;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF6A9FBF)
        : AppColors.paletteBorder;
    final background = selected
        ? const Color(0xFF2F3438)
        : AppColors.workspace;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.statusText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.statusText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A9FBF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.paletteLabel,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    configured ? Icons.check_circle_outline : Icons.circle_outlined,
                    size: 14,
                    color: configured
                        ? Colors.green.shade600
                        : AppColors.paletteLabel,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    configured ? 'Configured' : 'Not set up',
                    style: TextStyle(
                      color: configured
                          ? Colors.green.shade600
                          : AppColors.paletteLabel,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _providerCardStatusText(testResult!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: switch (testResult!.status) {
                      AiEnhanceConnectionStatus.valid =>
                        Colors.green.shade600,
                      AiEnhanceConnectionStatus.networkError =>
                        Colors.orange.shade800,
                      AiEnhanceConnectionStatus.invalid => Colors.red.shade700,
                    },
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _providerCardStatusText(AiEnhanceConnectionResult result) {
  final message = result.message?.trim();
  if (message != null && message.isNotEmpty) {
    return message;
  }
  return result.summary;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.statusText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.statusText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.paletteLabel,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyableCommandRow extends StatelessWidget {
  const _CopyableCommandRow({required this.command});

  final String command;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SSH command copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.workspace,
        border: Border.all(color: AppColors.paletteBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(
                color: AppColors.statusText,
                fontFamily: 'Menlo',
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy SSH command',
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy, size: 18),
            color: AppColors.paletteLabel,
          ),
        ],
      ),
    );
  }
}
