import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';

List<PlatformMenuItemGroup> buildImagePlatformMenuGroups({
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
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Crop to Selection',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyX,
            shift: true,
          ),
          onSelected: onCropToSelection,
        ),
        PlatformMenuItem(
          label: 'Auto Crop',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyX,
            control: true,
            alt: true,
          ),
          onSelected: onAutoCrop,
        ),
        PlatformMenuItem(
          label: 'Resize Image...',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyR),
          onSelected: onResizeImage,
        ),
        PlatformMenuItem(
          label: 'Resize Canvas...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyR,
            shift: true,
          ),
          onSelected: onResizeCanvas,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Flip Horizontal',
          onSelected: onFlipHorizontal,
        ),
        PlatformMenuItem(
          label: 'Flip Vertical',
          onSelected: onFlipVertical,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Rotate 90° Clockwise',
          onSelected: onRotate90Clockwise,
        ),
        PlatformMenuItem(
          label: 'Rotate 90° Counter-Clockwise',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyG),
          onSelected: onRotate90CounterClockwise,
        ),
        PlatformMenuItem(
          label: 'Rotate 180°',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyJ),
          onSelected: onRotate180,
        ),
        PlatformMenuItem(
          label: 'Free Rotate',
          onSelected: onFreeRotate,
        ),
        PlatformMenuItem(
          label: 'Rotate...',
          onSelected: onRotate,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Flatten',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyF,
            shift: true,
          ),
          onSelected: onFlatten,
        ),
      ],
    ),
  ];
}
