import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_components.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/avatar.dart';
import 'package:interior_design/data/models.dart';

/// The profile-picture rules the web's `avatar.ts` sets: JPEG, PNG or WebP,
/// at most 10 MB picked, scaled down to 512 px before it is stored.
void main() {
  group('checkAvatarFile', () {
    test('takes JPEG, PNG and WebP, whatever the case', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'PNG', 'JpG']) {
        expect(
          checkAvatarFile(extension: ext, size: 1000),
          isNull,
          reason: ext,
        );
      }
    });

    test('turns away other types', () {
      expect(checkAvatarFile(extension: 'gif', size: 1000), isNotNull);
      expect(checkAvatarFile(extension: 'pdf', size: 1000), isNotNull);
    });

    test('allows exactly 10 MB, not more', () {
      expect(
        checkAvatarFile(extension: 'png', size: avatarMaxPickedBytes),
        isNull,
      );
      expect(
        checkAvatarFile(extension: 'png', size: avatarMaxPickedBytes + 1),
        contains('10 MB'),
      );
    });

    test('an unknown size is let through', () {
      expect(checkAvatarFile(extension: 'png', size: null), isNull);
    });
  });

  test('file types map to the stored name and content type', () {
    expect(avatarContentType('png'), 'image/png');
    expect(avatarContentType('WEBP'), 'image/webp');
    expect(avatarContentType('jpeg'), 'image/jpeg');
    expect(avatarExtension('image/png'), 'png');
    expect(avatarExtension('image/webp'), 'webp');
    expect(avatarExtension('image/jpeg'), 'jpg');
  });

  group('avatarTargetSize', () {
    test('scales the longer side down to 512, keeping the shape', () {
      expect(avatarTargetSize(2048, 1024), (width: 512, height: 256));
      expect(avatarTargetSize(1000, 4000), (width: 128, height: 512));
    });

    test('never enlarges a small picture', () {
      expect(avatarTargetSize(300, 200), (width: 300, height: 200));
      expect(avatarTargetSize(512, 512), (width: 512, height: 512));
    });

    test('a very thin picture keeps at least one pixel', () {
      expect(avatarTargetSize(10000, 1).height, 1);
    });
  });

  group('shrinkAvatar', () {
    Future<Uint8List> png(int width, int height) async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..color = const ui.Color(0xFF336699),
      );
      final image = await recorder.endRecording().toImage(width, height);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }

    Future<ui.Codec> open(Uint8List bytes) => ui.instantiateImageCodec(bytes);

    testWidgets('scales a large picture down to 512 px as PNG', (tester) async {
      await tester.runAsync(() async {
        final result = await shrinkAvatar(await png(1200, 600), 'image/jpeg');
        expect(result.contentType, 'image/png');
        final frame = await (await open(result.bytes)).getNextFrame();
        expect(frame.image.width, 512);
        expect(frame.image.height, 256);
      });
    });

    testWidgets('keeps a small picture exactly as it is', (tester) async {
      await tester.runAsync(() async {
        final original = await png(200, 100);
        final result = await shrinkAvatar(original, 'image/webp');
        expect(result.bytes, original);
        expect(result.contentType, 'image/webp');
      });
    });

    testWidgets('hands back a file it cannot read unchanged', (tester) async {
      await tester.runAsync(() async {
        final junk = Uint8List.fromList([1, 2, 3, 4]);
        final result = await shrinkAvatar(junk, 'image/jpeg');
        expect(result.bytes, junk);
        expect(result.contentType, 'image/jpeg');
      });
    });
  });

  test('the profile reads the picture address, or none', () {
    Map<String, dynamic> row(String? url) => {
      'UserID': 'u',
      'Email': 'a@b.c',
      'FullName': 'Ada Lovelace',
      'UserName': 'ada',
      'AvatarUrl': url,
    };
    expect(
      AppUserProfile.fromJson(row('https://x/avatars/u/a.png')).avatarUrl,
      'https://x/avatars/u/a.png',
    );
    expect(AppUserProfile.fromJson(row(null)).avatarUrl, isNull);
  });

  testWidgets('AppAvatar shows the initials when there is no picture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const Scaffold(body: AppAvatar(initials: 'AL', size: 48)),
      ),
    );
    expect(find.text('AL'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('AppAvatar falls back to the initials if the picture fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const Scaffold(
          body: AppAvatar(
            initials: 'AL',
            size: 48,
            imageUrl: 'http://localhost:1/none.png',
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    // the test HTTP client fails every request, so the error builder shows
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('AL'), findsOneWidget);
  });
}
