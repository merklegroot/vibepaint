import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/theme/app_colors.dart';

class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.layers,
    required this.activeIndex,
    required this.onLayerSelected,
    required this.onToggleVisibility,
    required this.onAddLayer,
    required this.onDeleteLayer,
    this.canDeleteLayer = false,
  });

  static const double width = 180;

  final List<PaintLayer> layers;
  final int activeIndex;
  final ValueChanged<int> onLayerSelected;
  final ValueChanged<int> onToggleVisibility;
  final VoidCallback onAddLayer;
  final ValueChanged<int> onDeleteLayer;
  final bool canDeleteLayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          left: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Layers',
                    style: TextStyle(
                      color: AppColors.statusText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _PanelIconButton(
                  icon: Icons.add,
                  tooltip: 'Add layer',
                  onPressed: onAddLayer,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: layers.length,
              itemBuilder: (context, index) {
                final layer = layers[index];
                final isActive = index == activeIndex;
                return _LayerRow(
                  layer: layer,
                  isActive: isActive,
                  canDelete: canDeleteLayer && layers.length > 1,
                  onTap: () => onLayerSelected(index),
                  onToggleVisibility: () => onToggleVisibility(index),
                  onDelete: () => onDeleteLayer(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final PaintLayer layer;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.workspace : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              _PanelIconButton(
                icon: layer.visible ? Icons.visibility : Icons.visibility_off,
                tooltip: layer.visible ? 'Hide layer' : 'Show layer',
                onPressed: onToggleVisibility,
                size: 28,
              ),
              Expanded(
                child: Text(
                  layer.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: layer.visible
                        ? AppColors.statusText
                        : AppColors.paletteLabel,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (canDelete)
                _PanelIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete layer',
                  onPressed: onDelete,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 32,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.paletteLabel),
      ),
    );
  }
}
