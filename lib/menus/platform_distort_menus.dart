import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildDistortPlatformMenuGroups({
  required VoidCallback onBulge,
  required VoidCallback onFrostedGlass,
  required VoidCallback onPixelate,
  required VoidCallback onPolarInversion,
  required VoidCallback onTileReflection,
  required VoidCallback onTwist,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(label: 'Bulge...', onSelected: onBulge),
        PlatformMenuItem(label: 'Frosted Glass...', onSelected: onFrostedGlass),
        PlatformMenuItem(label: 'Pixelate...', onSelected: onPixelate),
        PlatformMenuItem(
          label: 'Polar Inversion...',
          onSelected: onPolarInversion,
        ),
        PlatformMenuItem(
          label: 'Tile Reflection...',
          onSelected: onTileReflection,
        ),
        PlatformMenuItem(label: 'Twist...', onSelected: onTwist),
      ],
    ),
  ];
}
