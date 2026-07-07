import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

class ColorPalettePanel extends StatelessWidget {
  const ColorPalettePanel({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double width = 72;

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const primarySize = 36.0;
    const swatchSize = 24.0;
    const gap = 4.0;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.palettePanel,
        border: Border.all(color: AppColors.paletteBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Colors',
              style: TextStyle(
                color: AppColors.paletteLabel,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Swatch(
            color: AppColors.presetColors[selectedIndex],
            size: primarySize,
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          for (var row = 0; row < 6; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 5 ? 0 : gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    Builder(
                      builder: (context) {
                        final index = row * 2 + col;
                        return _Swatch(
                          color: AppColors.presetColors[index],
                          size: swatchSize,
                          selected: index == selectedIndex,
                          onTap: () => onSelected(index),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
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
