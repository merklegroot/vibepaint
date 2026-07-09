import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/theme/app_colors.dart';

List<Widget> buildInWindowEditMenuChildren({
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
  required bool hasSelection,
  required VoidCallback onPickPrimaryColor,
  required VoidCallback onPickSecondaryColor,
  required VoidCallback onSwapColors,
  required VoidCallback onResetColors,
}) {
  final menuStyle = ButtonStyle(
    foregroundColor: const WidgetStatePropertyAll(AppColors.statusText),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  return [
    MenuItemButton(
      style: menuStyle,
      onPressed: canUndo ? onUndo : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyZ),
      child: const Text('Undo'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canRedo ? onRedo : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyZ, shift: true),
      child: const Text('Redo'),
    ),
    const Divider(height: 1),
    MenuItemButton(
      style: menuStyle,
      onPressed: canCutCopy ? onCut : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyX),
      child: const Text('Cut'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canCutCopy ? onCopy : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyC),
      child: const Text('Copy'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canCutCopy ? onCopyMerged : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyC, shift: true),
      child: const Text('Copy Merged'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canPaste ? onPaste : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyV),
      child: const Text('Paste'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canPaste ? onPasteIntoNewLayer : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyV, shift: true),
      child: const Text('Paste Into New Layer'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canPaste ? onPasteIntoNewImage : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyV, alt: true),
      child: const Text('Paste Into New Image'),
    ),
    const Divider(height: 1),
    MenuItemButton(
      style: menuStyle,
      onPressed: onSelectAll,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyA),
      child: const Text('Select All'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: canDeselect ? onDeselect : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyA, shift: true),
      child: const Text('Deselect All'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: hasSelection ? onEraseSelection : null,
      shortcut: const SingleActivator(LogicalKeyboardKey.delete),
      child: const Text('Erase Selection'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: hasSelection ? onFillSelection : null,
      child: const Text('Fill Selection'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: hasSelection ? onInvertSelection : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyI),
      child: const Text('Invert Selection'),
    ),
    MenuItemButton(
      style: menuStyle,
      onPressed: hasSelection ? onOffsetSelection : null,
      shortcut: platformMenuShortcut(LogicalKeyboardKey.keyO, shift: true),
      child: const Text('Offset Selection...'),
    ),
    const Divider(height: 1),
    SubmenuButton(
      style: menuStyle,
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
      ),
      menuChildren: [
        MenuItemButton(
          style: menuStyle,
          onPressed: onPickPrimaryColor,
          child: const Text('Primary Color...'),
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: onPickSecondaryColor,
          child: const Text('Secondary Color...'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          style: menuStyle,
          onPressed: onSwapColors,
          child: const Text('Swap Colors'),
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: onResetColors,
          child: const Text('Reset Colors'),
        ),
      ],
      child: const Text('Palette'),
    ),
  ];
}
