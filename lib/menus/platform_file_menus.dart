import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/menus/platform_edit_menus.dart';

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
}) {
  final appMenuGroups = <PlatformMenuItem>[
    if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about))
      const PlatformMenuItemGroup(
        members: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
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
      label: 'Edit',
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
  ];
}
