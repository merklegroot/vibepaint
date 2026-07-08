import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

enum AiEnhancePreviewAction { apply, regenerate, cancel }

/// Shows a preview of the Grok-enhanced image with Apply / Regenerate / Cancel.
Future<AiEnhancePreviewAction> showAiEnhancePreviewDialog({
  required BuildContext context,
  required Uint8List pngBytes,
  required int width,
  required int height,
}) async {
  final action = await showDialog<AiEnhancePreviewAction>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AiEnhancePreviewDialog(
      pngBytes: pngBytes,
      width: width,
      height: height,
    ),
  );
  return action ?? AiEnhancePreviewAction.cancel;
}

class _AiEnhancePreviewDialog extends StatefulWidget {
  const _AiEnhancePreviewDialog({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;

  @override
  State<_AiEnhancePreviewDialog> createState() =>
      _AiEnhancePreviewDialogState();
}

class _AiEnhancePreviewDialogState extends State<_AiEnhancePreviewDialog> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final image = await decodeImageBytes(widget.pngBytes);
    if (mounted) {
      setState(() => _image = image);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final aspect = (widget.width / widget.height).clamp(0.25, 4.0);
    const maxContentWidth = 520.0;
    final maxPreviewHeight =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(180.0, 420.0);

    var previewWidth = maxContentWidth;
    var previewHeight = previewWidth / aspect;
    if (previewHeight > maxPreviewHeight) {
      previewHeight = maxPreviewHeight;
      previewWidth = previewHeight * aspect;
    }

    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'AI Enhance Preview',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: maxContentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Review the enhanced result before applying it to the canvas.',
                style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.workspace,
                      border: Border.all(color: AppColors.paletteBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: image == null
                          ? const Center(child: CircularProgressIndicator())
                          : RawImage(
                              image: image,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            AiEnhancePreviewAction.cancel,
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            AiEnhancePreviewAction.regenerate,
          ),
          child: const Text('Regenerate'),
        ),
        FilledButton(
          onPressed: image == null
              ? null
              : () => Navigator.of(context).pop(
                  AiEnhancePreviewAction.apply,
                ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
