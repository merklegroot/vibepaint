import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildBlurPlatformMenuGroups({
  required VoidCallback onFragment,
  required VoidCallback onGaussianBlur,
  required VoidCallback onMotionBlur,
  required VoidCallback onRadialBlur,
  required VoidCallback onUnfocus,
  required VoidCallback onZoomBlur,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Fragment...',
          onSelected: onFragment,
        ),
        PlatformMenuItem(
          label: 'Gaussian Blur...',
          onSelected: onGaussianBlur,
        ),
        PlatformMenuItem(
          label: 'Motion Blur...',
          onSelected: onMotionBlur,
        ),
        PlatformMenuItem(
          label: 'Radial Blur...',
          onSelected: onRadialBlur,
        ),
        PlatformMenuItem(
          label: 'Unfocus...',
          onSelected: onUnfocus,
        ),
        PlatformMenuItem(
          label: 'Zoom Blur...',
          onSelected: onZoomBlur,
        ),
      ],
    ),
  ];
}
