import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';

List<PlatformMenu> buildMacosPlatformMenus({
  required VoidCallback? onNew,
  required VoidCallback onOpen,
  required VoidCallback onSave,
  required VoidCallback onSaveAs,
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
  ];
}
