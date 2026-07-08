import 'package:flutter/material.dart';
import 'package:vibepaint/models/layer_blend_mode.dart';
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
    required this.onDuplicateLayer,
    required this.onDeleteLayer,
    required this.onMoveLayerUp,
    required this.onMoveLayerDown,
    required this.onMergeDown,
    required this.onRenameLayer,
    required this.onOpacityChanged,
    required this.onBlendModeChanged,
    required this.canMoveLayerUp,
    required this.canMoveLayerDown,
    required this.canMergeDown,
    required this.canDeleteLayer,
  });

  static const double width = 220;

  final List<PaintLayer> layers;
  final int activeIndex;
  final ValueChanged<int> onLayerSelected;
  final ValueChanged<int> onToggleVisibility;
  final VoidCallback onAddLayer;
  final ValueChanged<int> onDuplicateLayer;
  final ValueChanged<int> onDeleteLayer;
  final ValueChanged<int> onMoveLayerUp;
  final ValueChanged<int> onMoveLayerDown;
  final ValueChanged<int> onMergeDown;
  final void Function(int index, String name) onRenameLayer;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<LayerBlendMode> onBlendModeChanged;
  final bool Function(int index) canMoveLayerUp;
  final bool Function(int index) canMoveLayerDown;
  final bool Function(int index) canMergeDown;
  final bool canDeleteLayer;

  @override
  Widget build(BuildContext context) {
    final activeLayer = layers[activeIndex];

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Layers',
                  style: TextStyle(
                    color: AppColors.statusText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _PanelIconButton(
                      icon: Icons.add,
                      tooltip: 'Add layer',
                      onPressed: onAddLayer,
                    ),
                    _PanelIconButton(
                      icon: Icons.copy,
                      tooltip: 'Duplicate layer',
                      onPressed: () => onDuplicateLayer(activeIndex),
                    ),
                    _PanelIconButton(
                      icon: Icons.arrow_upward,
                      tooltip: 'Move layer up',
                      enabled: canMoveLayerUp(activeIndex),
                      onPressed: () => onMoveLayerUp(activeIndex),
                    ),
                    _PanelIconButton(
                      icon: Icons.arrow_downward,
                      tooltip: 'Move layer down',
                      enabled: canMoveLayerDown(activeIndex),
                      onPressed: () => onMoveLayerDown(activeIndex),
                    ),
                    _PanelIconButton(
                      icon: Icons.merge,
                      tooltip: 'Merge down',
                      enabled: canMergeDown(activeIndex),
                      onPressed: () => onMergeDown(activeIndex),
                    ),
                    _PanelIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete layer',
                      enabled: canDeleteLayer,
                      onPressed: () => onDeleteLayer(activeIndex),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: layers.length,
              itemBuilder: (context, displayIndex) {
                final index = layers.length - 1 - displayIndex;
                final layer = layers[index];
                return _LayerRow(
                  layer: layer,
                  isActive: index == activeIndex,
                  onTap: () => onLayerSelected(index),
                  onToggleVisibility: () => onToggleVisibility(index),
                  onRename: (name) => onRenameLayer(index, name),
                );
              },
            ),
          ),
          _LayerProperties(
            opacity: activeLayer.opacity,
            blendMode: activeLayer.blendMode,
            onOpacityChanged: onOpacityChanged,
            onBlendModeChanged: onBlendModeChanged,
          ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatefulWidget {
  const _LayerRow({
    required this.layer,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onRename,
  });

  final PaintLayer layer;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onRename;

  @override
  State<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends State<_LayerRow> {
  late final TextEditingController _nameController;
  var _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
  }

  @override
  void didUpdateWidget(covariant _LayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.layer.name != widget.layer.name) {
      _nameController.text = widget.layer.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _commitRename() {
    widget.onRename(_nameController.text);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.isActive ? AppColors.workspace : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: widget.isActive ? null : widget.onTap,
        onDoubleTap: _startEditing,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              _PanelIconButton(
                icon: widget.layer.visible
                    ? Icons.visibility
                    : Icons.visibility_off,
                tooltip: widget.layer.visible ? 'Hide layer' : 'Show layer',
                onPressed: widget.onToggleVisibility,
                size: 28,
              ),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.statusText,
                          fontSize: 12,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _commitRename(),
                        onEditingComplete: _commitRename,
                      )
                    : GestureDetector(
                        onTap: widget.onTap,
                        onDoubleTap: _startEditing,
                        child: Text(
                          widget.layer.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.layer.visible
                                ? AppColors.statusText
                                : AppColors.paletteLabel,
                            fontSize: 12,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
              ),
              if (widget.layer.opacity < 1.0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${(widget.layer.opacity * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.paletteLabel,
                      fontSize: 10,
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

class _LayerProperties extends StatelessWidget {
  const _LayerProperties({
    required this.opacity,
    required this.blendMode,
    required this.onOpacityChanged,
    required this.onBlendModeChanged,
  });

  final double opacity;
  final LayerBlendMode blendMode;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<LayerBlendMode> onBlendModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Opacity',
                style: TextStyle(color: AppColors.paletteLabel, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(opacity * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.statusText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: opacity,
              min: 0,
              max: 1,
              onChanged: onOpacityChanged,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Blend mode',
            style: TextStyle(color: AppColors.paletteLabel, fontSize: 12),
          ),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.workspace,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.paletteBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LayerBlendMode>(
                value: blendMode,
                isExpanded: true,
                dropdownColor: AppColors.palettePanel,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                style: const TextStyle(color: AppColors.statusText, fontSize: 12),
                items: [
                  for (final mode in LayerBlendMode.values)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(mode.label),
                    ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    onBlendModeChanged(mode);
                  }
                },
              ),
            ),
          ),
        ],
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
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          color: enabled ? AppColors.paletteLabel : AppColors.paletteBorder,
        ),
      ),
    );
  }
}
