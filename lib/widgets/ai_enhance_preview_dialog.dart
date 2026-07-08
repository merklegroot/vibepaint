import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Preview dialog after Image Playground returns a result.
///
/// Returns `true` (Apply), `false` (Regenerate), or `null` (Cancel / dismiss).
Future<bool?> showAiEnhancePreviewDialog({
  required BuildContext context,
  required Uint8List pngBytes,
  required int width,
  required int height,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A303A),
        title: const Text(
          'AI Enhance',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Preview the generated image. Apply places it on the active '
                'layer (undoable). Regenerate opens Image Playground again.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 360,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E232B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3D4654)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.memory(
                        pngBytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$width×$height',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Regenerate'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}
