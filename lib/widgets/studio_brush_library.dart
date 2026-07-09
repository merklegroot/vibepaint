import 'package:flutter/material.dart';

import 'package:vibepaint/models/studio_brush_preset.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/studio_brush_renderer.dart';

/// Compact Procreate-style brush picker for the studio brush tool.
class StudioBrushLibrary extends StatefulWidget {
  const StudioBrushLibrary({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
    required this.onClose,
  });

  final StudioBrushPresetId selectedPreset;
  final ValueChanged<StudioBrushPresetId> onPresetSelected;
  final VoidCallback onClose;

  static const double width = 248;

  @override
  State<StudioBrushLibrary> createState() => _StudioBrushLibraryState();
}

class _StudioBrushLibraryState extends State<StudioBrushLibrary> {
  late String _activeCategory;

  @override
  void initState() {
    super.initState();
    _activeCategory = studioBrushPresetById(widget.selectedPreset).category;
  }

  List<String> get _categories {
    return kStudioBrushPresets.map((preset) => preset.category).toSet().toList();
  }

  List<StudioBrushPreset> get _visiblePresets {
    return kStudioBrushPresets
        .where((preset) => preset.category == _activeCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: StudioBrushLibrary.width,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: AppColors.palettePanel.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.paletteBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LibraryHeader(onClose: widget.onClose),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CategoryRail(
                    categories: _categories,
                    activeCategory: _activeCategory,
                    onCategorySelected: (category) {
                      setState(() => _activeCategory = category);
                    },
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      itemCount: _visiblePresets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final preset = _visiblePresets[index];
                        return _BrushPresetTile(
                          preset: preset,
                          selected: preset.id == widget.selectedPreset,
                          onTap: () => widget.onPresetSelected(preset.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Brush Library',
              style: TextStyle(
                color: AppColors.statusText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.paletteLabel,
            tooltip: 'Close',
            style: IconButton.styleFrom(
              minimumSize: const Size(30, 30),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == activeCategory;
          final icon = _categoryIcon(category);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Tooltip(
              message: category,
              child: Material(
                color: selected
                    ? const Color(0xFF007ACC)
                    : AppColors.workspace,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onCategorySelected(category),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected
                          ? Colors.white
                          : AppColors.paletteLabel,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Inks' => Icons.draw,
      'Pastels' => Icons.texture,
      _ => Icons.brush,
    };
  }
}

class _BrushPresetTile extends StatelessWidget {
  const _BrushPresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final StudioBrushPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF007ACC) : AppColors.workspace,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.statusText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BrushPreviewPainter(
                    settings: preset.settings,
                    strokeColor: selected ? Colors.white : AppColors.statusText,
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

class _BrushPreviewPainter extends CustomPainter {
  _BrushPreviewPainter({
    required this.settings,
    required this.strokeColor,
  });

  final StudioBrushSettings settings;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.palettePanel,
    );
    paintStudioBrushPreviewStroke(canvas, size, settings, color: strokeColor);
  }

  @override
  bool shouldRepaint(covariant _BrushPreviewPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.strokeColor != strokeColor;
  }
}
