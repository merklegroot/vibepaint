import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ollama_client.dart';

/// Shows progress while pulling an Ollama model.
Future<void> showOllamaPullProgressDialog({
  required BuildContext context,
  required Future<void> Function(
    void Function(OllamaPullProgress progress) onProgress,
  )
  work,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final status = ValueNotifier<OllamaPullProgress>(
    const OllamaPullProgress(status: 'Starting download…'),
  );
  final startedAt = DateTime.now();

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OllamaPullProgressDialog(
        status: status,
        startedAt: startedAt,
      ),
    ),
  );

  await Future<void>.delayed(Duration.zero);

  try {
    await work((progress) => status.value = progress);
  } on AiEnhanceException catch (error) {
    if (navigator.mounted) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    rethrow;
  } finally {
    status.dispose();
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

String _formatElapsed(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

class _OllamaPullProgressDialog extends StatefulWidget {
  const _OllamaPullProgressDialog({
    required this.status,
    required this.startedAt,
  });

  final ValueNotifier<OllamaPullProgress> status;
  final DateTime startedAt;

  @override
  State<_OllamaPullProgressDialog> createState() =>
      _OllamaPullProgressDialogState();
}

class _OllamaPullProgressDialogState extends State<_OllamaPullProgressDialog> {
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    widget.status.addListener(_onStatus);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _elapsedSeconds =
            DateTime.now().difference(widget.startedAt).inSeconds;
      });
    });
  }

  void _onStatus() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.status.removeListener(_onStatus);
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.status.value;
    final fraction = progress.fraction;

    return AlertDialog(
      title: const Text('Pulling Ollama model'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fraction != null)
              LinearProgressIndicator(value: fraction.clamp(0, 1))
            else
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(progress.message),
            const SizedBox(height: 12),
            Text(
              'Elapsed ${_formatElapsed(_elapsedSeconds)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
