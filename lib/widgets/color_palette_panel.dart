import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/widgets/color_wells_control.dart';

class ColorPalettePanel extends StatelessWidget {
  const ColorPalettePanel({
    super.key,
    required this.primaryColor,
    required this.primaryPresetIndex,
    required this.onPrimarySelected,
    required this.canvasBackgroundColor,
    required this.colorTarget,
    required this.onColorTargetChanged,
    required this.onCanvasBackgroundChanged,
    required this.onSwapColors,
    required this.onResetColors,
    this.onPrimaryDoubleTap,
    this.onSecondaryDoubleTap,
  });

  final Color primaryColor;
  final int? primaryPresetIndex;
  final ValueChanged<int> onPrimarySelected;
  final Color canvasBackgroundColor;
  final ColorWellTarget colorTarget;
  final ValueChanged<ColorWellTarget> onColorTargetChanged;
  final ValueChanged<Color> onCanvasBackgroundChanged;
  final VoidCallback onSwapColors;
  final VoidCallback onResetColors;
  final VoidCallback? onPrimaryDoubleTap;
  final VoidCallback? onSecondaryDoubleTap;

  @override
  Widget build(BuildContext context) {
    const swatchSize = 24.0;
    const gap = 4.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          top: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Row(
        children: [
          ColorWellsControl(
            primaryColor: primaryColor,
            secondaryColor: canvasBackgroundColor,
            activeTarget: colorTarget,
            onPrimaryTap: () => onColorTargetChanged(ColorWellTarget.primary),
            onSecondaryTap: () =>
                onColorTargetChanged(ColorWellTarget.canvasBackground),
            onPrimaryDoubleTap: onPrimaryDoubleTap,
            onSecondaryDoubleTap: onSecondaryDoubleTap,
            onSwap: onSwapColors,
            onReset: onResetColors,
          ),
          const SizedBox(width: 16),
          for (var i = 0; i < AppColors.presetColors.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            _Swatch(
              color: AppColors.presetColors[i],
              size: swatchSize,
              selected: _isPresetSelected(i),
              onTap: () => _handlePresetTap(i),
            ),
          ],
          if (colorTarget == ColorWellTarget.canvasBackground) ...[
            const SizedBox(width: gap),
            _Swatch(
              color: transparentCanvasBackground,
              size: swatchSize,
              selected: isTransparentCanvasBackground(canvasBackgroundColor),
              checkerboard: true,
              onTap: () => onCanvasBackgroundChanged(transparentCanvasBackground),
            ),
          ],
        ],
      ),
    );
  }

  bool _isPresetSelected(int index) {
    final color = AppColors.presetColors[index];
    return switch (colorTarget) {
      ColorWellTarget.primary => primaryPresetIndex == index,
      ColorWellTarget.canvasBackground =>
        canvasBackgroundColor.toARGB32() == color.toARGB32(),
    };
  }

  void _handlePresetTap(int index) {
    switch (colorTarget) {
      case ColorWellTarget.primary:
        onPrimarySelected(index);
      case ColorWellTarget.canvasBackground:
        onCanvasBackgroundChanged(AppColors.presetColors[index]);
    }
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
    this.checkerboard = false,
  });

  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;
  final bool checkerboard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checkerboard ? null : color,
          border: Border.all(
            color: selected ? Colors.white : AppColors.paletteBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected && !checkerboard
              ? const [
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: checkerboard
            ? CustomPaint(
                painter: const CanvasCheckerboardPainter(),
                size: Size(size, size),
              )
            : null,
      ),
    );
  }
}
