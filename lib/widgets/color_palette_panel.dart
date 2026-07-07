import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

class ColorPalettePanel extends StatelessWidget {
  const ColorPalettePanel({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Colors',
            style: TextStyle(
              color: AppColors.paletteLabel,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          _Swatch(
            color: AppColors.presetColors[selectedIndex],
            size: primarySize,
            selected: true,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          for (var i = 0; i < AppColors.presetColors.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            _Swatch(
              color: AppColors.presetColors[i],
              size: swatchSize,
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.paletteBorder),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
