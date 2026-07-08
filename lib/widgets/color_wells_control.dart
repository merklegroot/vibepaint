import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';

/// Classic overlapping primary / secondary color wells with swap and reset.
class ColorWellsControl extends StatelessWidget {
  const ColorWellsControl({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.activeTarget,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.onSwap,
    required this.onReset,
  });

  static const double wellSize = 28;
  static const double wellOffset = 14;

  final Color primaryColor;
  final Color secondaryColor;
  final ColorWellTarget activeTarget;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final VoidCallback onSwap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wellSize + wellOffset + 18,
      height: wellSize + wellOffset + 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: wellOffset,
            top: wellOffset,
            child: _OverlappingWell(
              color: secondaryColor,
              size: wellSize,
              selected: activeTarget == ColorWellTarget.canvasBackground,
              onTap: onSecondaryTap,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _OverlappingWell(
              color: primaryColor,
              size: wellSize,
              selected: activeTarget == ColorWellTarget.primary,
              onTap: onPrimaryTap,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _WellToolButton(
              icon: Icons.swap_horiz,
              tooltip: 'Swap colors',
              onPressed: onSwap,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _ResetColorsButton(onPressed: onReset),
          ),
        ],
      ),
    );
  }
}

class _OverlappingWell extends StatelessWidget {
  const _OverlappingWell({
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
    final checkerboard = isTransparentCanvasBackground(color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checkerboard ? null : color,
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: 1,
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: checkerboard
            ? CustomPaint(
                painter: const CanvasCheckerboardPainter(cellSize: 4),
                size: Size(size, size),
              )
            : null,
      ),
    );
  }
}

class _WellToolButton extends StatelessWidget {
  const _WellToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.paletteLabel,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _ResetColorsButton extends StatelessWidget {
  const _ResetColorsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reset colors',
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: defaultCanvasBackground,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  color: AppColors.presetColors.first,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
