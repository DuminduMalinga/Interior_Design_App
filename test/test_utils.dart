import 'dart:io';

import 'package:flutter/services.dart';

/// Flutter tests render text in the "Ahem" font, where every glyph is a full
/// em wide, so text measures about twice as wide as it does on a device and
/// reports overflows that never happen. Loading the Roboto that ships with
/// the SDK gives realistic text metrics.
Future<void> loadRoboto() async {
  // The test runner lives under <sdk>/bin/cache/, which locates the SDK even
  // when FLUTTER_ROOT is not set.
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final cache = exe.indexOf('/bin/cache/');
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      (cache == -1 ? null : exe.substring(0, cache));
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;

  final loader = FontLoader('Roboto');
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('roboto-') &&
        name.endsWith('.ttf') &&
        !name.contains('italic')) {
      loader.addFont(
        Future.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    }
  }
  await loader.load();
}
