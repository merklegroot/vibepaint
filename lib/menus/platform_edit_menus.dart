import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/theme/app_colors.dart';

List<PlatformMenuItemGroup> buildEditPlatformMenuGroups({
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
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Undo',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyZ),
          onSelected: canUndo ? onUndo : null,
        ),
        PlatformMenuItem(
          label: 'Redo',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyZ,
            shift: true,
          ),
          onSelected: canRedo ? onRedo : null,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Cut',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyX),
          onSelected: canCutCopy ? onCut : null,
        ),
        PlatformMenuItem(
          label: 'Copy',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyC),
          onSelected: canCutCopy ? onCopy : null,
        ),
        PlatformMenuItem(
          label: 'Copy Merged',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyC,
            shift: true,
          ),
          onSelected: canCutCopy ? onCopyMerged : null,
        ),
        PlatformMenuItem(
          label: 'Paste',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyV),
          onSelected: canPaste ? onPaste : null,
        ),
        PlatformMenuItem(
          label: 'Paste Into New Layer',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyV,
            shift: true,
          ),
          onSelected: canPaste ? onPasteIntoNewLayer : null,
        ),
        PlatformMenuItem(
          label: 'Paste Into New Image',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyV,
            alt: true,
          ),
          onSelected: canPaste ? onPasteIntoNewImage : null,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Select All',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyA),
          onSelected: onSelectAll,
        ),
        PlatformMenuItem(
          label: 'Deselect All',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyA,
            shift: true,
          ),
          onSelected: canDeselect ? onDeselect : null,
        ),
        PlatformMenuItem(
          label: 'Erase Selection',
          shortcut: const SingleActivator(LogicalKeyboardKey.delete),
          onSelected: hasSelection ? onEraseSelection : null,
        ),
        PlatformMenuItem(
          label: 'Fill Selection',
          onSelected: hasSelection ? onFillSelection : null,
        ),
        PlatformMenuItem(
          label: 'Invert Selection',
          shortcut: platformMenuShortcut(LogicalKeyboardKey.keyI),
          onSelected: hasSelection ? onInvertSelection : null,
        ),
        PlatformMenuItem(
          label: 'Offset Selection...',
          shortcut: platformMenuShortcut(
            LogicalKeyboardKey.keyO,
            shift: true,
          ),
          onSelected: hasSelection ? onOffsetSelection : null,
        ),
      ],
    ),
    PlatformMenuItemGroup(
      members: [
        PlatformMenu(
          label: 'Palette',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Primary Color...',
                  onSelected: onPickPrimaryColor,
                ),
                PlatformMenuItem(
                  label: 'Secondary Color...',
                  onSelected: onPickSecondaryColor,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Swap Colors',
                  onSelected: onSwapColors,
                ),
                PlatformMenuItem(
                  label: 'Reset Colors',
                  onSelected: onResetColors,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

List<PlatformMenuItem> buildEditPlatformMenuItems({
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
  return buildEditPlatformMenuGroups(
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
  ).expand((group) => group.members).toList();
}
