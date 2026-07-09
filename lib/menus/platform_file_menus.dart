import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/menus/platform_adjustments_menus.dart';
import 'package:vibepaint/menus/platform_edit_menus.dart';
import 'package:vibepaint/menus/platform_image_menus.dart';

List<PlatformMenu> buildMacosPlatformMenus({
  required VoidCallback? onNew,
  required VoidCallback onOpen,
  required VoidCallback onSave,
  required VoidCallback onSaveAs,
  required VoidCallback onSelectAll,
  required VoidCallback onDeselect,
  required VoidCallback onInvertSelection,
  required VoidCallback onDeleteSelection,
  required bool hasSelection,
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
      menus: [
        PlatformMenuItemGroup(
          members: buildEditPlatformMenuItems(
            onSelectAll: onSelectAll,
            onDeselect: onDeselect,
            onInvertSelection: onInvertSelection,
            onDeleteSelection: onDeleteSelection,
            canDeleteSelection: hasSelection,
          ),
        ),
      ],
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
  ];
}
