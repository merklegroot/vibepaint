import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibepaint/utils/ai_enhance.dart';

/// Shows a non-dismissible progress dialog while [work] runs.
/// Subscribes to progress *before* starting work so early status isn't missed.
Future<T> showAiEnhanceProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() work,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final status = ValueNotifier<AiEnhanceProgress>(
    const AiEnhanceProgress(
      message: 'Starting AI enhancement…',
      phase: 'start',
    ),
  );
  final startedAt = DateTime.now();

  final progressSub = aiEnhanceProgressStream().listen((event) {
    status.value = event;
  });

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AiEnhanceProgressDialog(
        status: status,
        startedAt: startedAt,
      ),
    ),
  );

  await Future<void>.delayed(Duration.zero);

  try {
    return await work();
  } finally {
    await progressSub.cancel();
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

class _AiEnhanceProgressDialog extends StatefulWidget {
  const _AiEnhanceProgressDialog({
    required this.status,
    required this.startedAt,
  });

  final ValueNotifier<AiEnhanceProgress> status;
  final DateTime startedAt;

  @override
  State<_AiEnhanceProgressDialog> createState() =>
      _AiEnhanceProgressDialogState();
}

class _AiEnhanceProgressDialogState extends State<_AiEnhanceProgressDialog> {
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
    final elapsed = progress.elapsedSeconds > 0
        ? progress.elapsedSeconds
        : _elapsedSeconds;

    final subtitle = switch (progress.phase) {
      'prepare' => 'Preparing sketch · ${_formatElapsed(elapsed)}',
      'upload' => 'Uploading · ${_formatElapsed(elapsed)}',
      'generate' => 'Generating · ${_formatElapsed(elapsed)}',
      'decode' => 'Downloading result · ${_formatElapsed(elapsed)}',
      'done' => 'Complete · ${_formatElapsed(elapsed)}',
      _ => 'Elapsed ${_formatElapsed(elapsed)}',
    };

    return AlertDialog(
      title: const Text('AI Enhance'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(progress.message),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
