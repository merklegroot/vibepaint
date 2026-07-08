import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/image_transforms.dart';

class ResizeDimensionsResult {
  const ResizeDimensionsResult({
    required this.width,
    required this.height,
    this.anchor = CanvasAnchor.center,
  });

  final int width;
  final int height;
  final CanvasAnchor anchor;
}

class ResizeDimensionsDialog extends StatefulWidget {
  const ResizeDimensionsDialog({
    super.key,
    required this.title,
    required this.initialWidth,
    required this.initialHeight,
    this.showAnchor = false,
  });

  final String title;
  final int initialWidth;
  final int initialHeight;
  final bool showAnchor;

  @override
  State<ResizeDimensionsDialog> createState() => _ResizeDimensionsDialogState();
}

class _ResizeDimensionsDialogState extends State<ResizeDimensionsDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  CanvasAnchor _anchor = CanvasAnchor.center;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.initialWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.initialHeight.toString(),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _submit() {
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    if (width == null || height == null || width < 1 || height < 1) {
      return;
    }

    Navigator.of(context).pop(
      ResizeDimensionsResult(
        width: width,
        height: height,
        anchor: _anchor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: Text(
        widget.title,
        style: const TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.statusText),
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      labelStyle: TextStyle(color: AppColors.paletteLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.statusText),
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      labelStyle: TextStyle(color: AppColors.paletteLabel),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showAnchor) ...[
              const SizedBox(height: 16),
              const Text(
                'Anchor',
                style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SegmentedButton<CanvasAnchor>(
                segments: const [
                  ButtonSegment(
                    value: CanvasAnchor.topLeft,
                    label: Text('Top left'),
                  ),
                  ButtonSegment(
                    value: CanvasAnchor.center,
                    label: Text('Center'),
                  ),
                ],
                selected: {_anchor},
                onSelectionChanged: (selection) {
                  setState(() => _anchor = selection.first);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
