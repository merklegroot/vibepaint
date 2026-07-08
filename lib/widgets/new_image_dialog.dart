import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';

class NewImageDialog extends StatefulWidget {
  const NewImageDialog({super.key});

  @override
  State<NewImageDialog> createState() => _NewImageDialogState();
}

class _NewImageDialogState extends State<NewImageDialog> {
  Color _backgroundColor = defaultCanvasBackground;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'New image',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Discard the current canvas and start fresh.',
              style: TextStyle(color: AppColors.paletteLabel),
            ),
            const SizedBox(height: 16),
            const Text(
              'Canvas background',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < AppColors.presetColors.length; i++)
                  _BackgroundSwatch(
                    color: AppColors.presetColors[i],
                    selected: _backgroundColor.toARGB32() ==
                        AppColors.presetColors[i].toARGB32(),
                    onTap: () => setState(
                      () => _backgroundColor = AppColors.presetColors[i],
                    ),
                  ),
                _BackgroundSwatch(
                  color: transparentCanvasBackground,
                  selected: isTransparentCanvasBackground(_backgroundColor),
                  checkerboard: true,
                  onTap: () => setState(
                    () => _backgroundColor = transparentCanvasBackground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_backgroundColor),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.checkerboard = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool checkerboard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: checkerboard ? null : color,
          border: Border.all(
            color: selected ? Colors.white : AppColors.paletteBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: checkerboard
            ? const CustomPaint(
                painter: CanvasCheckerboardPainter(),
              )
            : null,
      ),
    );
  }
}
