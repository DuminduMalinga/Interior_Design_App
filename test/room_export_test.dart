import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/room_export.dart';

/// Saving and sharing a room's picture, as the web's 3D view exports a PNG.
void main() {
  group('exportFileStem', () {
    test('names a picture like the web: lower case, dashes between words', () {
      expect(
        exportFileStem('Living Room', 'conversation'),
        'living-room-conversation',
      );
      expect(
        exportFileStem('Master Bedroom', 'bed_north'),
        'master-bedroom-bed-north',
      );
    });

    test('collapses any run of odd characters into one dash', () {
      expect(
        exportFileStem('Kitchen / Dining', 'L-shaped'),
        'kitchen-dining-l-shaped',
      );
      // ") " and the joining "-" are one run, so one dash, not two
      expect(exportFileStem('Bath (en-suite)', 'x'), 'bath-en-suite-x');
    });

    test('never leaves a character a file name could choke on', () {
      final stem = exportFileStem('Salle d\'été: 1/2 \\ <test>', 'a|b?c*');
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(stem), isTrue, reason: stem);
    });
  });

  group('capturePng', () {
    testWidgets('draws the boundary as a PNG at the requested scale', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 120,
                height: 80,
                child: ColoredBox(color: Color(0xFF336699)),
              ),
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        final png = await capturePng(key, pixelRatio: 2);
        expect(png, isNotNull);
        // the PNG signature
        expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
        final frame = await (await ui.instantiateImageCodec(
          png,
        )).getNextFrame();
        expect(frame.image.width, 240);
        expect(frame.image.height, 160);
      });
    });

    testWidgets('is null when the key is not on screen', (tester) async {
      await tester.runAsync(() async {
        expect(await capturePng(GlobalKey()), isNull);
      });
    });

    testWidgets('is null when the key is not a repaint boundary', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: key, width: 10, height: 10),
        ),
      );
      await tester.runAsync(() async {
        expect(await capturePng(key), isNull);
      });
    });
  });

  group('pictureShareParams', () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    test('shares one PNG under the room\'s file name, with a caption', () {
      final params = pictureShareParams(
        png: png,
        fileName: 'living-room-conversation.png',
        text: 'Living Room: Conversation layout',
      );
      expect(params.text, 'Living Room: Conversation layout');
      expect(params.files, hasLength(1));
      expect(params.files!.single.mimeType, 'image/png');
      expect(params.fileNameOverrides, ['living-room-conversation.png']);
      expect(params.sharePositionOrigin, isNull);
    });

    test('passes the button area for iPad\'s share popover', () {
      const origin = Rect.fromLTWH(10, 20, 30, 40);
      expect(
        pictureShareParams(
          png: png,
          fileName: 'a.png',
          text: 't',
          origin: origin,
        ).sharePositionOrigin,
        origin,
      );
    });

    test('the file carries the picture bytes', () async {
      final params = pictureShareParams(png: png, fileName: 'a.png', text: 't');
      expect(await params.files!.single.readAsBytes(), png);
    });
  });
}
