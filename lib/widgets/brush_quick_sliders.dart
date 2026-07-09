import 'package:flutter/material.dart';
import 'package:vibepaint/models/studio_brush_preset.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';

/// Procreate-style vertical brush controls shown over the canvas.
class BrushQuickSliders extends StatelessWidget {
  const BrushQuickSliders({
    super.key,
    required this.brushSize,
    required this.brushOpacity,
    required this.primaryColor,
    required this.activePreset,
    required this.libraryOpen,
    required this.canUndo,
    required this.canRedo,
    required this.onBrushSizeChanged,
    required this.onBrushOpacityChanged,
    required this.onPrimaryColorTap,
    required this.onBrushLibraryTap,
    required this.onUndo,
    required this.onRedo,
  });

  final double brushSize;
  final double brushOpacity;
  final Color primaryColor;
  final StudioBrushPresetId activePreset;
  final bool libraryOpen;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onBrushOpacityChanged;
  final VoidCallback onPrimaryColorTap;
  final VoidCallback onBrushLibraryTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  static const double width = 52;

  @override
  Widget build(BuildContext context) {
    final sizeFraction = _normalize(
      brushSize,
      BrushSizeControl.minSize,
      BrushSizeControl.maxSize,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.palettePanel.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.paletteBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrushLibraryButton(
              preset: studioBrushPresetById(activePreset),
              selected: libraryOpen,
              onTap: onBrushLibraryTap,
            ),
            const SizedBox(height: 10),
            _VerticalBrushSlider(
              value: sizeFraction,
              tooltip: 'Brush size',
              onChanged: (value) => onBrushSizeChanged(
                _denormalize(
                  value,
                  BrushSizeControl.minSize,
                  BrushSizeControl.maxSize,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ColorSwatchButton(
              color: primaryColor,
              onTap: onPrimaryColorTap,
            ),
            const SizedBox(height: 10),
            _VerticalBrushSlider(
              value: brushOpacity.clamp(0.05, 1),
              tooltip: 'Brush opacity',
              onChanged: onBrushOpacityChanged,
            ),
            const SizedBox(height: 12),
            _QuickActionButton(
              icon: Icons.undo,
              tooltip: 'Undo',
              enabled: canUndo,
              onPressed: onUndo,
            ),
            const SizedBox(height: 6),
            _QuickActionButton(
              icon: Icons.redo,
              tooltip: 'Redo',
              enabled: canRedo,
              onPressed: onRedo,
            ),
          ],
        ),
      ),
    );
  }

  static double _normalize(double value, double min, double max) {
    if (max <= min) {
      return 0;
    }
    return ((value - min) / (max - min)).clamp(0, 1);
  }

  static double _denormalize(double fraction, double min, double max) {
    return min + (max - min) * fraction.clamp(0, 1);
  }
}

class _BrushLibraryButton extends StatelessWidget {
  const _BrushLibraryButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final StudioBrushPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Brush library',
      child: Material(
        color: selected ? const Color(0xFF007ACC) : AppColors.workspace,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              preset.previewIcon,
              size: 20,
              color: selected ? Colors.white : AppColors.statusText,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalBrushSlider extends StatefulWidget {
  const _VerticalBrushSlider({
    required this.value,
    required this.tooltip,
    required this.onChanged,
  });

  final double value;
  final String tooltip;
  final ValueChanged<double> onChanged;

  @override
  State<_VerticalBrushSlider> createState() => _VerticalBrushSliderState();
}

class _VerticalBrushSliderState extends State<_VerticalBrushSlider> {
  static const _trackHeight = 112.0;
  static const _trackWidth = 8.0;
  static const _handleWidth = 28.0;
  static const _handleHeight = 14.0;

  double? _dragValue;

  double get _displayValue => (_dragValue ?? widget.value).clamp(0, 1);

  void _updateFromLocalDy(double localDy) {
    final usable = _trackHeight - _handleHeight;
    final clampedDy = (localDy - _handleHeight / 2).clamp(0, usable);
    setState(() {
      _dragValue = 1 - (clampedDy / usable);
    });
  }

  void _commitDrag() {
    if (_dragValue != null) {
      widget.onChanged(_dragValue!);
    }
    setState(() => _dragValue = null);
  }

  @override
  Widget build(BuildContext context) {
    final usable = _trackHeight - _handleHeight;
    final handleTop = (1 - _displayValue) * usable;

    return Tooltip(
      message: widget.tooltip,
      child: SizedBox(
        width: _handleWidth,
        height: _trackHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) =>
              _updateFromLocalDy(details.localPosition.dy),
          onVerticalDragUpdate: (details) =>
              _updateFromLocalDy(details.localPosition.dy),
          onVerticalDragEnd: (_) => _commitDrag(),
          onVerticalDragCancel: _commitDrag,
          onTapDown: (details) {
            _updateFromLocalDy(details.localPosition.dy);
            _commitDrag();
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: _handleHeight / 2,
                child: Container(
                  width: _trackWidth,
                  height: usable,
                  decoration: BoxDecoration(
                    color: AppColors.workspace,
                    borderRadius: BorderRadius.circular(_trackWidth / 2),
                    border: Border.all(color: AppColors.paletteBorder),
                  ),
                ),
              ),
              Positioned(
                top: handleTop,
                child: Container(
                  width: _handleWidth,
                  height: _handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.statusText,
                    borderRadius: BorderRadius.circular(_handleHeight / 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Primary color',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.statusText, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        color: AppColors.statusText,
        disabledColor: AppColors.paletteBorder,
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.workspace,
        ),
      ),
    );
  }
}
