import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/edit_menu_widgets.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// In-window File and Edit menus for Windows and Linux.
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.canNew,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onCut,
    required this.onCopy,
    required this.onCopyMerged,
    required this.onPaste,
    required this.onPasteIntoNewLayer,
    required this.onPasteIntoNewImage,
    required this.canCutCopy,
    required this.canPaste,
    required this.onSelectAll,
    required this.onDeselect,
    required this.canDeselect,
    required this.onEraseSelection,
    required this.onFillSelection,
    required this.onInvertSelection,
    required this.onOffsetSelection,
    required this.onDeleteSelection,
    required this.hasSelection,
    required this.onPickPrimaryColor,
    required this.onPickSecondaryColor,
    required this.onSwapColors,
    required this.onResetColors,
    required this.onCropToSelection,
    required this.onAutoCrop,
    required this.onResizeImage,
    required this.onResizeCanvas,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
    required this.onRotate90Clockwise,
    required this.onRotate90CounterClockwise,
    required this.onRotate180,
    required this.onFreeRotate,
    required this.onRotate,
    required this.onFlatten,
    required this.onAutoLevel,
    required this.onBlackAndWhite,
    required this.onBrightnessContrast,
    required this.onCurves,
    required this.onHueSaturation,
    required this.onInvertColors,
    required this.onLevels,
    required this.onPosterize,
    required this.onSepia,
    required this.onGlow,
    required this.onSharpen,
    required this.onSoftenPortrait,
    required this.onInkSketch,
    required this.onOilPainting,
    required this.onPencilSketch,
    required this.onFragment,
    required this.onGaussianBlur,
    required this.onMotionBlur,
    required this.onRadialBlur,
    required this.onUnfocus,
    required this.onZoomBlur,
    required this.onBulge,
    required this.onFrostedGlass,
    required this.onPixelate,
    required this.onPolarInversion,
    required this.onTileReflection,
    required this.onTwist,
    required this.onClouds,
    required this.onJuliaFractal,
    required this.onMandelbrotFractal,
    required this.onEdgeDetect,
    required this.onEmboss,
    required this.onOutline,
    required this.onRelief,
    required this.onDithering,
    this.onOpenSettings,
  });

  final bool canNew;
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onCut;
  final VoidCallback onCopy;
  final VoidCallback onCopyMerged;
  final VoidCallback onPaste;
  final VoidCallback onPasteIntoNewLayer;
  final VoidCallback onPasteIntoNewImage;
  final bool canCutCopy;
  final bool canPaste;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselect;
  final bool canDeselect;
  final VoidCallback onEraseSelection;
  final VoidCallback onFillSelection;
  final VoidCallback onInvertSelection;
  final VoidCallback onOffsetSelection;
  final VoidCallback onDeleteSelection;
  final bool hasSelection;
  final VoidCallback onPickPrimaryColor;
  final VoidCallback onPickSecondaryColor;
  final VoidCallback onSwapColors;
  final VoidCallback onResetColors;
  final VoidCallback? onCropToSelection;
  final VoidCallback onAutoCrop;
  final VoidCallback onResizeImage;
  final VoidCallback onResizeCanvas;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;
  final VoidCallback onRotate90Clockwise;
  final VoidCallback onRotate90CounterClockwise;
  final VoidCallback onRotate180;
  final VoidCallback onFreeRotate;
  final VoidCallback onRotate;
  final VoidCallback onFlatten;
  final VoidCallback onAutoLevel;
  final VoidCallback onBlackAndWhite;
  final VoidCallback onBrightnessContrast;
  final VoidCallback onCurves;
  final VoidCallback onHueSaturation;
  final VoidCallback onInvertColors;
  final VoidCallback onLevels;
  final VoidCallback onPosterize;
  final VoidCallback onSepia;
  final VoidCallback onGlow;
  final VoidCallback onSharpen;
  final VoidCallback onSoftenPortrait;
  final VoidCallback onInkSketch;
  final VoidCallback onOilPainting;
  final VoidCallback onPencilSketch;
  final VoidCallback onFragment;
  final VoidCallback onGaussianBlur;
  final VoidCallback onMotionBlur;
  final VoidCallback onRadialBlur;
  final VoidCallback onUnfocus;
  final VoidCallback onZoomBlur;
  final VoidCallback onBulge;
  final VoidCallback onFrostedGlass;
  final VoidCallback onPixelate;
  final VoidCallback onPolarInversion;
  final VoidCallback onTileReflection;
  final VoidCallback onTwist;
  final VoidCallback onClouds;
  final VoidCallback onJuliaFractal;
  final VoidCallback onMandelbrotFractal;
  final VoidCallback onEdgeDetect;
  final VoidCallback onEmboss;
  final VoidCallback onOutline;
  final VoidCallback onRelief;
  final VoidCallback onDithering;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (!useInWindowFileMenu) {
      return const SizedBox.shrink();
    }

    final menuStyle = ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(AppColors.statusText),
      overlayColor: WidgetStatePropertyAll(
        AppColors.statusText.withValues(alpha: 0.08),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );

    return MenuBar(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
      ),
      children: [
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: canNew ? onNew : null,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyN),
              child: const Text('New'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onOpen,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyO),
              child: const Text('Open...'),
            ),
            MenuItemButton(
              onPressed: onSave,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyS),
              child: const Text('Save'),
            ),
            MenuItemButton(
              onPressed: onSaveAs,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyS,
                shift: true,
              ),
              child: const Text('Save As...'),
            ),
            const Divider(height: 1),
            if (onOpenSettings != null)
              MenuItemButton(
                onPressed: onOpenSettings,
                shortcut: platformMenuShortcut(LogicalKeyboardKey.comma),
                child: const Text('Settings...'),
              ),
            if (onOpenSettings != null) const Divider(height: 1),
            MenuItemButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Exit'),
            ),
          ],
          child: const Text('File'),
        ),
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: buildInWindowEditMenuChildren(
            onUndo: onUndo,
            onRedo: onRedo,
            canUndo: canUndo,
            canRedo: canRedo,
            onCut: onCut,
            onCopy: onCopy,
            onCopyMerged: onCopyMerged,
            onPaste: onPaste,
            onPasteIntoNewLayer: onPasteIntoNewLayer,
            onPasteIntoNewImage: onPasteIntoNewImage,
            canCutCopy: canCutCopy,
            canPaste: canPaste,
            onSelectAll: onSelectAll,
            onDeselect: onDeselect,
            canDeselect: canDeselect,
            onEraseSelection: onEraseSelection,
            onFillSelection: onFillSelection,
            onInvertSelection: onInvertSelection,
            onOffsetSelection: onOffsetSelection,
            hasSelection: hasSelection,
            onPickPrimaryColor: onPickPrimaryColor,
            onPickSecondaryColor: onPickSecondaryColor,
            onSwapColors: onSwapColors,
            onResetColors: onResetColors,
          ),
          child: const Text('Edit'),
        ),
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: onCropToSelection,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyX,
                shift: true,
              ),
              child: const Text('Crop to Selection'),
            ),
            MenuItemButton(
              onPressed: onAutoCrop,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyX,
                control: true,
                alt: true,
              ),
              child: const Text('Auto Crop'),
            ),
            MenuItemButton(
              onPressed: onResizeImage,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyR),
              child: const Text('Resize Image...'),
            ),
            MenuItemButton(
              onPressed: onResizeCanvas,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyR,
                shift: true,
              ),
              child: const Text('Resize Canvas...'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onFlipHorizontal,
              child: const Text('Flip Horizontal'),
            ),
            MenuItemButton(
              onPressed: onFlipVertical,
              child: const Text('Flip Vertical'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onRotate90Clockwise,
              child: const Text('Rotate 90° Clockwise'),
            ),
            MenuItemButton(
              onPressed: onRotate90CounterClockwise,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyG),
              child: const Text('Rotate 90° Counter-Clockwise'),
            ),
            MenuItemButton(
              onPressed: onRotate180,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyJ),
              child: const Text('Rotate 180°'),
            ),
            MenuItemButton(
              onPressed: onFreeRotate,
              child: const Text('Free Rotate'),
            ),
            MenuItemButton(
              onPressed: onRotate,
              child: const Text('Rotate...'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onFlatten,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyF,
                shift: true,
              ),
              child: const Text('Flatten'),
            ),
          ],
          child: const Text('Image'),
        ),
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: onAutoLevel,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyL,
                shift: true,
              ),
              child: const Text('Auto Level'),
            ),
            MenuItemButton(
              onPressed: onBlackAndWhite,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyG,
                shift: true,
              ),
              child: const Text('Black and White'),
            ),
            MenuItemButton(
              onPressed: onBrightnessContrast,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyB,
                shift: true,
              ),
              child: const Text('Brightness / Contrast...'),
            ),
            MenuItemButton(
              onPressed: onCurves,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyM,
                shift: true,
              ),
              child: const Text('Curves...'),
            ),
            MenuItemButton(
              onPressed: onHueSaturation,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyU,
                shift: true,
              ),
              child: const Text('Hue / Saturation...'),
            ),
            MenuItemButton(
              onPressed: onInvertColors,
              child: const Text('Invert Colors'),
            ),
            MenuItemButton(
              onPressed: onLevels,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyL),
              child: const Text('Levels...'),
            ),
            MenuItemButton(
              onPressed: onPosterize,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyP,
                shift: true,
              ),
              child: const Text('Posterize...'),
            ),
            MenuItemButton(
              onPressed: onSepia,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyE,
                shift: true,
              ),
              child: const Text('Sepia'),
            ),
          ],
          child: const Text('Adjustments'),
        ),
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onGlow,
                  child: const Text('Glow...'),
                ),
                MenuItemButton(
                  onPressed: onSharpen,
                  child: const Text('Sharpen...'),
                ),
                MenuItemButton(
                  onPressed: onSoftenPortrait,
                  child: const Text('Soften Portrait...'),
                ),
              ],
              child: const Text('Photo'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onInkSketch,
                  child: const Text('Ink Sketch...'),
                ),
                MenuItemButton(
                  onPressed: onOilPainting,
                  child: const Text('Oil Painting...'),
                ),
                MenuItemButton(
                  onPressed: onPencilSketch,
                  child: const Text('Pencil Sketch...'),
                ),
              ],
              child: const Text('Artistic'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onFragment,
                  child: const Text('Fragment...'),
                ),
                MenuItemButton(
                  onPressed: onGaussianBlur,
                  child: const Text('Gaussian Blur...'),
                ),
                MenuItemButton(
                  onPressed: onMotionBlur,
                  child: const Text('Motion Blur...'),
                ),
                MenuItemButton(
                  onPressed: onRadialBlur,
                  child: const Text('Radial Blur...'),
                ),
                MenuItemButton(
                  onPressed: onUnfocus,
                  child: const Text('Unfocus...'),
                ),
                MenuItemButton(
                  onPressed: onZoomBlur,
                  child: const Text('Zoom Blur...'),
                ),
              ],
              child: const Text('Blurs'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onBulge,
                  child: const Text('Bulge...'),
                ),
                MenuItemButton(
                  onPressed: onFrostedGlass,
                  child: const Text('Frosted Glass...'),
                ),
                MenuItemButton(
                  onPressed: onPixelate,
                  child: const Text('Pixelate...'),
                ),
                MenuItemButton(
                  onPressed: onPolarInversion,
                  child: const Text('Polar Inversion...'),
                ),
                MenuItemButton(
                  onPressed: onTileReflection,
                  child: const Text('Tile Reflection...'),
                ),
                MenuItemButton(
                  onPressed: onTwist,
                  child: const Text('Twist...'),
                ),
              ],
              child: const Text('Distort'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onClouds,
                  child: const Text('Clouds...'),
                ),
                MenuItemButton(
                  onPressed: onJuliaFractal,
                  child: const Text('Julia Fractal...'),
                ),
                MenuItemButton(
                  onPressed: onMandelbrotFractal,
                  child: const Text('Mandelbrot Fractal...'),
                ),
              ],
              child: const Text('Render'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onEdgeDetect,
                  child: const Text('Edge Detect...'),
                ),
                MenuItemButton(
                  onPressed: onEmboss,
                  child: const Text('Emboss...'),
                ),
                MenuItemButton(
                  onPressed: onOutline,
                  child: const Text('Outline...'),
                ),
                MenuItemButton(
                  onPressed: onRelief,
                  child: const Text('Relief...'),
                ),
              ],
              child: const Text('Stylize'),
            ),
            SubmenuButton(
              style: menuStyle,
              menuStyle: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: onDithering,
                  child: const Text('Dithering...'),
                ),
              ],
              child: const Text('Color'),
            ),
          ],
          child: const Text('Effects'),
        ),
      ],
    );
  }
}
