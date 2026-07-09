import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildColorPlatformMenuGroups({
  required VoidCallback onDithering,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Dithering...',
          onSelected: onDithering,
        ),
      ],
    ),
  ];
}
