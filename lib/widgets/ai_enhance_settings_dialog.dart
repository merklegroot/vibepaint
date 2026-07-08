import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_settings.dart';
import 'package:vibepaint/theme/app_colors.dart';

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

  bool _isGrokConfigured() => _grokKeyController.text.trim().isNotEmpty;

  bool _isOllamaConfigured() =>
      _ollamaUrlController.text.trim().isNotEmpty &&
      _ollamaModelController.text.trim().isNotEmpty;

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
                status: _grokStatus,
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
                subtitle: 'Local or SSH tunnel',
                selected: _activeProvider == AiEnhanceProviderId.ollama,
                configured: _isOllamaConfigured(),
                status: _ollamaStatus,
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
          const SizedBox(height: 4),
          _statusRow(_grokStatus!),
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
                'Vision: llava, moondream, bakllava. Image output: x/flux2-klein',
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
          onChanged: (_) => setState(() => _ollamaStatus = null),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _testOllama,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Test connection'),
          ),
        ),
        if (_ollamaStatus != null) ...[
          const SizedBox(height: 4),
          _statusRow(_ollamaStatus!),
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
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool configured;
  final bool enabled;
  final VoidCallback onTap;
  final AiEnhanceConnectionStatus? status;

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
                  if (status != null) ...[
                    const Spacer(),
                    Icon(
                      status == AiEnhanceConnectionStatus.valid
                          ? Icons.link
                          : Icons.link_off,
                      size: 14,
                      color: switch (status) {
                        AiEnhanceConnectionStatus.valid =>
                          Colors.green.shade600,
                        AiEnhanceConnectionStatus.networkError =>
                          Colors.orange.shade800,
                        AiEnhanceConnectionStatus.invalid =>
                          Colors.red.shade700,
                        null => AppColors.paletteLabel,
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
