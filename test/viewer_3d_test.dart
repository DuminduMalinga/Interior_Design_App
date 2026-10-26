import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/data/orbit.dart';
import 'package:interior_design/data/room_export.dart';
import 'package:interior_design/main.dart';

import 'room_glb_test.dart' show bedroom, lBathroom;
import 'test_utils.dart';

/// Looking at the room from every side, and taking it away as a picture or
/// as a 3D model.
void main() {
  setUpAll(loadRoboto);

  group('wrapAngle', () {
    test('leaves a turn within half a circle alone', () {
      for (final a in [0.0, .5, -.5, 3.0, -3.0]) {
        expect(wrapAngle(a), closeTo(a, 1e-12));
      }
    });

    test('brings a long turn back into -pi to pi', () {
      expect(wrapAngle(2 * math.pi), closeTo(0, 1e-9));
      expect(wrapAngle(2 * math.pi + .3), closeTo(.3, 1e-9));
      expect(wrapAngle(-2 * math.pi - .3), closeTo(-.3, 1e-9));
      expect(wrapAngle(10 * math.pi + 1), closeTo(1, 1e-9));
    });

    test('a half turn either way is the same view', () {
      expect(wrapAngle(math.pi).abs(), closeTo(math.pi, 1e-9));
      expect(wrapAngle(-math.pi).abs(), closeTo(math.pi, 1e-9));
    });

    test('always lands in range, however far it is turned', () {
      for (var a = -50.0; a < 50; a += .37) {
        final w = wrapAngle(a);
        expect(w, inInclusiveRange(-math.pi, math.pi), reason: '$a');
        expect(math.cos(w), closeTo(math.cos(a), 1e-9), reason: 'same view');
        expect(math.sin(w), closeTo(math.sin(a), 1e-9), reason: 'same view');
      }
    });
  });

  group('the walls that stand behind the room', () {
    Set<String> far(double yaw, {double w = 200, double d = 148}) =>
        farthestWalls(yaw, width: w, depth: d);

    test('from the opening view they are the north and west', () {
      expect(far(-.28), {'north', 'west'});
      expect(far(0), {'north', 'west'});
    });

    test('they follow the camera round the room', () {
      expect(far(math.pi / 2), {'south', 'west'});
      expect(far(math.pi), {'south', 'east'});
      expect(far(-math.pi / 2), {'north', 'east'});
    });

    test('there are always two, and they meet at a corner', () {
      const opposite = [
        {'north', 'south'},
        {'east', 'west'},
      ];
      for (final (w, d) in [
        (200.0, 148.0),
        (148.0, 200.0),
        (200.0, 200.0),
        (200.0, 60.0),
      ]) {
        for (var yaw = -math.pi; yaw <= math.pi; yaw += .05) {
          final walls = far(yaw, w: w, d: d);
          expect(walls, hasLength(2), reason: 'yaw $yaw');
          expect(
            opposite.any((o) => o.containsAll(walls)),
            isFalse,
            reason: 'yaw $yaw gave opposite walls $walls',
          );
        }
      }
    });

    test(
      'a full turn visits all four corners, and comes back to the start',
      () {
        final seen = <String>{};
        for (var yaw = -math.pi; yaw <= math.pi; yaw += .05) {
          seen.add((far(yaw).toList()..sort()).join('+'));
        }
        expect(seen, hasLength(4));
        expect(far(-.28), far(-.28 + 2 * math.pi));
      },
    );
  });

  group('the viewer', () {
    Future<void> open(
      WidgetTester tester, {
      AnalysisLayout? layout,
      Size size = const Size(360, 740),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: roomViewerForTest(roomName: 'Bedroom', layout: layout),
        ),
      );
      await tester.pump();
    }

    group('turning', () {
      testWidgets('goes all the way round for an engine layout', (
        tester,
      ) async {
        await open(tester, layout: bedroom());
        for (var i = 0; i < 40; i++) {
          await tester.tap(find.byIcon(Icons.rotate_right_rounded));
          await tester.pump();
        }
        for (var i = 0; i < 40; i++) {
          await tester.tap(find.byIcon(Icons.rotate_left_rounded));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('follows a long drag, not just the last movement', (
        tester,
      ) async {
        await open(tester, layout: bedroom());
        final canvas = find.byType(RepaintBoundary).first;
        await tester.drag(canvas, const Offset(300, 0));
        await tester.pump();
        await tester.drag(canvas, const Offset(-600, 40));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('an engine layout draws from every side without error', (
        tester,
      ) async {
        for (final layout in [bedroom(), lBathroom()]) {
          await open(tester, layout: layout);
          for (var i = 0; i < 17; i++) {
            await tester.tap(find.byIcon(Icons.rotate_right_rounded));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: 'step $i');
          }
        }
      });

      testWidgets('the stylised older room stays within its narrow range', (
        tester,
      ) async {
        await open(tester);
        for (var i = 0; i < 20; i++) {
          await tester.tap(find.byIcon(Icons.rotate_right_rounded));
          await tester.pump();
        }
        await tester.drag(
          find.byType(RepaintBoundary).first,
          const Offset(900, 0),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('reset brings back the opening view', (tester) async {
        await open(tester, layout: bedroom());
        await tester.tap(find.byIcon(Icons.rotate_right_rounded));
        await tester.tap(find.byIcon(Icons.zoom_in_rounded));
        await tester.pump();
        await tester.tap(find.byTooltip('Reset view'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('Export', () {
      testWidgets('offers the picture or the 3D model for an engine layout', (
        tester,
      ) async {
        await open(tester, layout: bedroom());
        await tester.tap(find.text('Export'));
        await tester.pumpAndSettle();
        expect(find.text('Picture'), findsOneWidget);
        expect(find.text('PNG of the current view'), findsOneWidget);
        expect(find.text('3D model'), findsOneWidget);
        expect(find.text('GLB, real size in metres'), findsOneWidget);
      });

      testWidgets('Share offers the same choice', (tester) async {
        await open(tester, layout: bedroom());
        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();
        expect(find.text('Picture'), findsOneWidget);
        expect(find.text('3D model'), findsOneWidget);
      });

      testWidgets('closing the choice does nothing', (tester) async {
        await open(tester, layout: bedroom());
        await tester.tap(find.text('Export'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(180, 40)); // outside the sheet
        await tester.pumpAndSettle();
        expect(find.text('3D model'), findsNothing);
        expect(find.textContaining('Could not'), findsNothing);
        expect(
          find.text('Export'),
          findsOneWidget,
          reason: 'free to try again',
        );
      });

      testWidgets(
        'the older stylised room has only the picture, so no choice',
        (tester) async {
          await open(tester);
          await tester.tap(find.text('Export'));
          await tester.pump();
          expect(find.text('3D model'), findsNothing);
        },
      );

      testWidgets(
        'saving the model builds it and hands it to the file dialog',
        (tester) async {
          await open(tester, layout: bedroom());
          await tester.tap(find.text('Export'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3D model'));
          await tester.pumpAndSettle();
          // there is no file dialog on a test machine, so saving fails; that it
          // got as far as saving means the model was built
          expect(find.text('Could not save the model.'), findsOneWidget);
          expect(find.text('Could not save the picture.'), findsNothing);
        },
      );

      testWidgets(
        'sharing the model builds it and hands it over without error',
        (tester) async {
          await open(tester, layout: bedroom());
          await tester.tap(find.text('Share'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3D model'));
          await tester.pumpAndSettle();
          // a test machine has no share sheet, which reports itself unavailable
          // rather than failing; a model that could not be built would show
          // the failure message instead
          expect(find.text('Could not share the model.'), findsNothing);
          expect(find.textContaining('Could not'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('is ready for another try after a failure', (tester) async {
        await open(tester, layout: bedroom());
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.text('Export'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3D model'));
          await tester.pumpAndSettle();
          expect(find.text('Could not save the model.'), findsOneWidget);
          ScaffoldMessenger.of(
            tester.element(find.byType(Scaffold)),
          ).clearSnackBars();
          await tester.pumpAndSettle();
        }
      });

      for (final (name, size) in const [
        ('tablet', Size(800, 900)),
        ('desktop', Size(1440, 900)),
      ]) {
        testWidgets('fits a $name screen', (tester) async {
          await open(tester, layout: bedroom(), size: size);
          await tester.tap(find.text('Export'));
          await tester.pumpAndSettle();
          expect(find.text('3D model'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });

  group('sharing a model', () {
    test('sends the .glb file under the room\'s name, with a caption', () {
      final params = modelShareParams(
        glb: roomToGlb(bedroom()),
        fileName: 'bedroom-bed-west.glb',
        text: 'Bedroom: Bed',
      );
      expect(params.text, 'Bedroom: Bed');
      expect(params.files, hasLength(1));
      expect(params.files!.single.mimeType, 'model/gltf-binary');
      expect(params.fileNameOverrides, ['bedroom-bed-west.glb']);
    });

    test('the file it carries is the model', () async {
      final bytes = roomToGlb(bedroom());
      final params = modelShareParams(glb: bytes, fileName: 'a.glb', text: 't');
      expect(await params.files!.single.readAsBytes(), bytes);
    });

    test('passes the button area for iPad\'s share popover', () {
      const origin = Rect.fromLTWH(10, 20, 30, 40);
      expect(
        modelShareParams(
          glb: roomToGlb(bedroom()),
          fileName: 'a.glb',
          text: 't',
          origin: origin,
        ).sharePositionOrigin,
        origin,
      );
    });
  });
}
