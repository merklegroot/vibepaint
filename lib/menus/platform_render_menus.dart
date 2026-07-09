import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildRenderPlatformMenuGroups({
  required VoidCallback onClouds,
  required VoidCallback onJuliaFractal,
  required VoidCallback onMandelbrotFractal,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(label: 'Clouds...', onSelected: onClouds),
        PlatformMenuItem(label: 'Julia Fractal...', onSelected: onJuliaFractal),
        PlatformMenuItem(
          label: 'Mandelbrot Fractal...',
          onSelected: onMandelbrotFractal,
        ),
      ],
    ),
  ];
}
