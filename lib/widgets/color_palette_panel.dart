import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';

class ColorPalettePanel extends StatelessWidget {
  const ColorPalettePanel({
    super.key,
    required this.selectedIndex,
    required this.onPrimarySelected,
    required this.canvasBackgroundColor,
    required this.colorTarget,
    required this.onColorTargetChanged,
    required this.onCanvasBackgroundChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onPrimarySelected;
  final Color canvasBackgroundColor;
  final ColorWellTarget colorTarget;
  final ValueChanged<ColorWellTarget> onColorTargetChanged;
  final ValueChanged<Color> onCanvasBackgroundChanged;

  @override
  Widget build(BuildContext context) {
    const primarySize = 36.0;
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
          _ColorWell(
            label: 'Primary',
            color: AppColors.presetColors[selectedIndex],
            size: primarySize,
            selected: colorTarget == ColorWellTarget.primary,
            onTap: () => onColorTargetChanged(ColorWellTarget.primary),
          ),
          const SizedBox(width: 12),
          _ColorWell(
            label: 'Canvas',
            color: canvasBackgroundColor,
            size: primarySize,
            selected: colorTarget == ColorWellTarget.canvasBackground,
            onTap: () => onColorTargetChanged(ColorWellTarget.canvasBackground),
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
      ColorWellTarget.primary => index == selectedIndex,
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

class _ColorWell extends StatelessWidget {
  const _ColorWell({
    required this.label,
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Swatch(
          color: color,
          size: size,
          selected: selected,
          checkerboard: isTransparentCanvasBackground(color),
          onTap: onTap,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.paletteLabel,
            fontSize: 11,
          ),
        ),
      ],
    );
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
