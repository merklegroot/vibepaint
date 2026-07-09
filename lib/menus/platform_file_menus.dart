import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/menus/platform_adjustments_menus.dart';
import 'package:vibepaint/menus/platform_effects_menus.dart';
import 'package:vibepaint/menus/platform_edit_menus.dart';
import 'package:vibepaint/menus/platform_image_menus.dart';

List<PlatformMenu> buildMacosPlatformMenus({
  required VoidCallback? onNew,
  required VoidCallback onOpen,
  required VoidCallback onSave,
  required VoidCallback onSaveAs,
  required VoidCallback onUndo,
  required VoidCallback onRedo,
  required bool canUndo,
  required bool canRedo,
  required VoidCallback onCut,
  required VoidCallback onCopy,
  required VoidCallback onCopyMerged,
  required VoidCallback onPaste,
  required VoidCallback onPasteIntoNewLayer,
  required VoidCallback onPasteIntoNewImage,
  required bool canCutCopy,
  required bool canPaste,
  required VoidCallback onSelectAll,
  required VoidCallback onDeselect,
  required bool canDeselect,
  required VoidCallback onEraseSelection,
  required VoidCallback onFillSelection,
  required VoidCallback onInvertSelection,
  required VoidCallback onOffsetSelection,
  required VoidCallback onDeleteSelection,
  required bool hasSelection,
  required VoidCallback onPickPrimaryColor,
  required VoidCallback onPickSecondaryColor,
  required VoidCallback onSwapColors,
  required VoidCallback onResetColors,
  required VoidCallback? onCropToSelection,
  required VoidCallback onAutoCrop,
  required VoidCallback onResizeImage,
  required VoidCallback onResizeCanvas,
  required VoidCallback onFlipHorizontal,
  required VoidCallback onFlipVertical,
  required VoidCallback onRotate90Clockwise,
  required VoidCallback onRotate90CounterClockwise,
  required VoidCallback onRotate180,
  required VoidCallback onFreeRotate,
  required VoidCallback onRotate,
  required VoidCallback onFlatten,
  required VoidCallback onAutoLevel,
  required VoidCallback onBlackAndWhite,
  required VoidCallback onBrightnessContrast,
  required VoidCallback onCurves,
  required VoidCallback onHueSaturation,
  required VoidCallback onInvertColors,
  required VoidCallback onLevels,
  required VoidCallback onPosterize,
  required VoidCallback onSepia,
  required VoidCallback onGlow,
  required VoidCallback onSharpen,
  required VoidCallback onSoftenPortrait,
  required VoidCallback onInkSketch,
  required VoidCallback onOilPainting,
  required VoidCallback onPencilSketch,
  required VoidCallback onFragment,
  required VoidCallback onGaussianBlur,
  required VoidCallback onMotionBlur,
  required VoidCallback onRadialBlur,
  required VoidCallback onUnfocus,
  required VoidCallback onZoomBlur,
  required VoidCallback onBulge,
  required VoidCallback onFrostedGlass,
  required VoidCallback onPixelate,
  required VoidCallback onPolarInversion,
  required VoidCallback onTileReflection,
  required VoidCallback onTwist,
  required VoidCallback onClouds,
  required VoidCallback onJuliaFractal,
  required VoidCallback onMandelbrotFractal,
  required VoidCallback onEdgeDetect,
  required VoidCallback onEmboss,
  required VoidCallback onOutline,
  required VoidCallback onRelief,
  required VoidCallback onDithering,
  VoidCallback? onOpenSettings,
}) {
  final appMenuGroups = <PlatformMenuItem>[
    if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about))
      const PlatformMenuItemGroup(
        members: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
        ],
      ),
    if (onOpenSettings != null)
      PlatformMenuItemGroup(
        members: [
          PlatformMenuItem(
            label: 'Settings…',
            shortcut: platformMenuShortcut(LogicalKeyboardKey.comma),
            onSelected: onOpenSettings,
          ),
        ],
      ),
    PlatformMenuItemGroup(
      members: [
        if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.hide))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.hide,
          ),
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.hideOtherApplications,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.hideOtherApplications,
          ),
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.showAllApplications,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.showAllApplications,
          ),
      ],
    ),
    const PlatformMenuItemGroup(
      members: [
        PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
      ],
    ),
  ];

  return [
    PlatformMenu(
      label: 'VibePaint',
      menus: appMenuGroups,
    ),
    PlatformMenu(
      label: 'File',
      menus: [
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'New',
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyN),
              onSelected: onNew,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'Open...',
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyO),
              onSelected: onOpen,
            ),
            PlatformMenuItem(
              label: 'Save',
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyS),
              onSelected: onSave,
            ),
            PlatformMenuItem(
              label: 'Save As...',
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyS,
                shift: true,
              ),
              onSelected: onSaveAs,
            ),
          ],
        ),
      ],
    ),
    PlatformMenu(
      label: platformEditMenuLabel,
      menus: buildEditPlatformMenuGroups(
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
    ),
    PlatformMenu(
      label: 'Image',
      menus: buildImagePlatformMenuGroups(
        onCropToSelection: onCropToSelection,
        onAutoCrop: onAutoCrop,
        onResizeImage: onResizeImage,
        onResizeCanvas: onResizeCanvas,
        onFlipHorizontal: onFlipHorizontal,
        onFlipVertical: onFlipVertical,
        onRotate90Clockwise: onRotate90Clockwise,
        onRotate90CounterClockwise: onRotate90CounterClockwise,
        onRotate180: onRotate180,
        onFreeRotate: onFreeRotate,
        onRotate: onRotate,
        onFlatten: onFlatten,
      ),
    ),
    PlatformMenu(
      label: 'Adjustments',
      menus: buildAdjustmentsPlatformMenuGroups(
        onAutoLevel: onAutoLevel,
        onBlackAndWhite: onBlackAndWhite,
        onBrightnessContrast: onBrightnessContrast,
        onCurves: onCurves,
        onHueSaturation: onHueSaturation,
        onInvertColors: onInvertColors,
        onLevels: onLevels,
        onPosterize: onPosterize,
        onSepia: onSepia,
      ),
    ),
    PlatformMenu(
      label: 'Effects',
      menus: buildEffectsPlatformMenuGroups(
        onGlow: onGlow,
        onSharpen: onSharpen,
        onSoftenPortrait: onSoftenPortrait,
        onInkSketch: onInkSketch,
        onOilPainting: onOilPainting,
        onPencilSketch: onPencilSketch,
        onFragment: onFragment,
        onGaussianBlur: onGaussianBlur,
        onMotionBlur: onMotionBlur,
        onRadialBlur: onRadialBlur,
        onUnfocus: onUnfocus,
        onZoomBlur: onZoomBlur,
        onBulge: onBulge,
        onFrostedGlass: onFrostedGlass,
        onPixelate: onPixelate,
        onPolarInversion: onPolarInversion,
        onTileReflection: onTileReflection,
        onTwist: onTwist,
        onClouds: onClouds,
        onJuliaFractal: onJuliaFractal,
        onMandelbrotFractal: onMandelbrotFractal,
        onEdgeDetect: onEdgeDetect,
        onEmboss: onEmboss,
        onOutline: onOutline,
        onRelief: onRelief,
        onDithering: onDithering,
      ),
    ),
  ];
}
