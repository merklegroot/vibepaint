import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';

List<PlatformMenuItem> buildEditPlatformMenuItems({
  required VoidCallback onSelectAll,
  required VoidCallback onDeselect,
  required VoidCallback onInvertSelection,
  required VoidCallback onDeleteSelection,
  required bool canDeleteSelection,
}) {
  return [
    PlatformMenuItem(
      label: 'Select All',
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyA),
      onSelected: onSelectAll,
    ),
    PlatformMenuItem(
      label: 'Deselect',
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyD),
      onSelected: onDeselect,
    ),
    PlatformMenuItem(
      label: 'Invert Selection',
      shortcut: platformMenuShortcut(
        LogicalKeyboardKey.keyI,
        shift: true,
        control: true,
      ),
      onSelected: onInvertSelection,
    ),
    PlatformMenuItem(
      label: 'Delete Selection',
      shortcut: const SingleActivator(LogicalKeyboardKey.delete),
      onSelected: canDeleteSelection ? onDeleteSelection : null,
    ),
  ];
}
