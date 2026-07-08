import 'package:flutter/material.dart';
import 'package:vibepaint/services/grok_api_key_storage.dart';
import 'package:vibepaint/services/grok_client.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// Opens the Grok API key settings dialog.
Future<void> showGrokSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const GrokSettingsDialog(),
  );
}

class GrokSettingsDialog extends StatefulWidget {
  const GrokSettingsDialog({super.key});

  @override
  State<GrokSettingsDialog> createState() => _GrokSettingsDialogState();
}

class _GrokSettingsDialogState extends State<GrokSettingsDialog> {
  final _storage = GrokApiKeyStorage();
  final _client = GrokClient();
  final _controller = TextEditingController();
  final _obscureNotifier = ValueNotifier<bool>(true);

  bool _loading = true;
  bool _busy = false;
  GrokConnectionStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStoredKey();
  }

  Future<void> _loadStoredKey() async {
    final stored = await _storage.read();
    if (!mounted) {
      return;
    }
    setState(() {
      _controller.text = stored ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _obscureNotifier.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await _storage.delete();
      if (mounted) {
        setState(() => _status = null);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await _storage.write(key);
      if (mounted) {
        setState(() => _status = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grok API key saved securely.'),
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

  Future<void> _testConnection() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _status = GrokConnectionStatus.invalid);
      return;
    }

    setState(() => _busy = true);
    try {
      final status = await _client.testConnection(key);
      if (mounted) {
        setState(() => _status = status);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _statusLabel(GrokConnectionStatus status) {
    return switch (status) {
      GrokConnectionStatus.valid => 'Valid',
      GrokConnectionStatus.invalid => 'Invalid',
      GrokConnectionStatus.networkError => 'Network error',
    };
  }

  Color _statusColor(GrokConnectionStatus status) {
    return switch (status) {
      GrokConnectionStatus.valid => Colors.green.shade700,
      GrokConnectionStatus.invalid => Colors.red.shade700,
      GrokConnectionStatus.networkError => Colors.orange.shade800,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Grok Settings',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your xAI Grok API key. It is stored securely on this device.',
                    style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: _obscureNotifier,
                    builder: (context, obscure, _) {
                      return TextField(
                        controller: _controller,
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
                                _obscureNotifier.value = !obscure,
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
                        onChanged: (_) {
                          if (_status != null) {
                            setState(() => _status = null);
                          }
                        },
                      );
                    },
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _status == GrokConnectionStatus.valid
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 18,
                          color: _statusColor(_status!),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_statusLabel(_status!)}',
                          style: TextStyle(
                            color: _statusColor(_status!),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: _busy || _loading ? null : _testConnection,
          child: const Text('Test Connection'),
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
