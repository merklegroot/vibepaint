import 'package:flutter/material.dart';

abstract final class AppColors {
  static const workspace = Color(0xFF3A3A3A);
  static const canvasBorder = Color(0xFF1E1E1E);
  static const statusBar = Color(0xFF2D2D30);
  static const statusText = Color(0xFFDCDCDC);
  static const palettePanel = Color(0xFF252528);
  static const paletteBorder = Color(0xFF46464A);
  static const paletteLabel = Color(0xFFB4B4B4);

  static const presetColorColumns = 16;
  static const presetColorRows = 2;

  /// Default palette: two rows of 16 swatches (vibrant top, pastel bottom).
  static const presetColors = <Color>[
    // Top row — grayscale + saturated hues
    Color(0xFFFFFFFF),
    Color(0xFF969696),
    Color(0xFF4B4B4B),
    Color(0xFFFF0000),
    Color(0xFFFF6600),
    Color(0xFFFFCC00),
    Color(0xFFFFFF00),
    Color(0xFF99FF00),
    Color(0xFF00FF00),
    Color(0xFF00FF99),
    Color(0xFF00FFFF),
    Color(0xFF0099FF),
    Color(0xFF0000FF),
    Color(0xFF9900FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0066),
    // Bottom row — grayscale + pastel tints
    Color(0xFF000000),
    Color(0xFF646464),
    Color(0xFF323232),
    Color(0xFFFF8080),
    Color(0xFFFFB380),
    Color(0xFFFFE680),
    Color(0xFFFFFF80),
    Color(0xFFCCFF80),
    Color(0xFF80FF80),
    Color(0xFF80FFCC),
    Color(0xFF80FFFF),
    Color(0xFF80CCFF),
    Color(0xFF8080FF),
    Color(0xFFCC80FF),
    Color(0xFFFF80FF),
    Color(0xFFFF80B3),
  ];
}
