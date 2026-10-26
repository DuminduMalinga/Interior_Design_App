import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Saving and sharing the picture of a furnished room, from the 3D view.
/// The web's 3D view exports a PNG too (`RoomView3D.tsx`); it can export the
/// 3D model as well, which this app, drawing the room itself, has no mesh for.

/// The file name, without extension, for a room's picture: the same rule as
/// the web's `fileStem`, so a room saved on either app is named alike.
String exportFileStem(String roomName, String layoutType) =>
    '$roomName-$layoutType'.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );

/// Draws what [key]'s `RepaintBoundary` currently shows as PNG bytes, or
/// null when it is not on screen yet.
Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 2}) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// What to hand the system share sheet for a room's picture.
ShareParams pictureShareParams({
  required Uint8List png,
  required String fileName,
  required String text,
  Rect? origin,
}) => ShareParams(
  text: text,
  files: [XFile.fromData(png, mimeType: 'image/png')],
  fileNameOverrides: [fileName],
  // iPad anchors its share popover to this
  sharePositionOrigin: origin,
);
