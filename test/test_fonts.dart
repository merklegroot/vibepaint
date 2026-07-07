import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteData> _loadFontFile(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.sublistView(bytes);
}

Future<String> _flutterSdkRoot() async {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }

  final result = await Process.run('flutter', ['sdk-path']);
  if (result.exitCode != 0) {
    throw StateError('Failed to locate Flutter SDK: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

Future<void> loadTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fontsDir =
      '${await _flutterSdkRoot()}/bin/cache/artifacts/material_fonts';

  final roboto = FontLoader('Roboto')
    ..addFont(_loadFontFile('$fontsDir/Roboto-Regular.ttf'))
    ..addFont(_loadFontFile('$fontsDir/Roboto-Medium.ttf'));

  final icons = FontLoader('MaterialIcons')
    ..addFont(_loadFontFile('$fontsDir/MaterialIcons-Regular.otf'));

  await Future.wait([roboto.load(), icons.load()]);
}
