import 'dart:typed_data';

import 'package:flutter/material.dart';

class CanvasClipboardData {
  const CanvasClipboardData({
    required this.pngBytes,
    required this.size,
    required this.origin,
  });

  final Uint8List pngBytes;
  final Size size;
  final Offset origin;
}

class CanvasClipboard {
  static CanvasClipboardData? _data;

  static bool get hasData => _data != null;

  static CanvasClipboardData? get data => _data;

  static void set(CanvasClipboardData data) {
    _data = data;
  }

  static void clear() {
    _data = null;
  }
}
