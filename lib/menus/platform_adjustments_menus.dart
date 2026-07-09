import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';

List<PlatformMenuItemGroup> buildAdjustmentsPlatformMenuGroups({
  required VoidCallback onAutoLevel,
  required VoidCallback onBlackAndWhite,
  required VoidCallback onBrightnessContrast,
  required VoidCallback onCurves,
  required VoidCallback onHueSaturation,
  required VoidCallback onInvertColors,
  required VoidCallback onLevels,
  required VoidCallback onPosterize,
  required VoidCallback onSepia,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Auto Level',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyL,
            shift: true,
          ),
          onSelected: onAutoLevel,
        ),
        PlatformMenuItem(
          label: 'Black and White',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyG,
            shift: true,
          ),
          onSelected: onBlackAndWhite,
        ),
        PlatformMenuItem(
          label: 'Brightness / Contrast...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyB,
            shift: true,
          ),
          onSelected: onBrightnessContrast,
        ),
        PlatformMenuItem(
          label: 'Curves...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyM,
            shift: true,
          ),
          onSelected: onCurves,
        ),
        PlatformMenuItem(
          label: 'Hue / Saturation...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyU,
            shift: true,
          ),
          onSelected: onHueSaturation,
        ),
        PlatformMenuItem(
          label: 'Invert Colors',
          onSelected: onInvertColors,
        ),
        PlatformMenuItem(
          label: 'Levels...',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyL),
          onSelected: onLevels,
        ),
        PlatformMenuItem(
          label: 'Posterize...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyP,
            shift: true,
          ),
          onSelected: onPosterize,
        ),
        PlatformMenuItem(
          label: 'Sepia',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyE,
            shift: true,
          ),
          onSelected: onSepia,
        ),
      ],
    ),
  ];
}
