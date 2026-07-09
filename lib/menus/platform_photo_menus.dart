import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildPhotoPlatformMenuGroups({
  required VoidCallback onGlow,
  required VoidCallback onSharpen,
  required VoidCallback onSoftenPortrait,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(label: 'Glow...', onSelected: onGlow),
        PlatformMenuItem(label: 'Sharpen...', onSelected: onSharpen),
        PlatformMenuItem(
          label: 'Soften Portrait...',
          onSelected: onSoftenPortrait,
        ),
      ],
    ),
  ];
}
