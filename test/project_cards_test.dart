import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_components.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/data/project_status.dart';
import 'package:interior_design/main.dart';
import 'package:interior_design/project_widgets.dart';

import 'test_utils.dart';

const _sizes = {
  'mobile': Size(360, 740),
  'tablet': Size(800, 900),
  'desktop': Size(1440, 900),
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 740),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.darkTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

ProjectSummary summary({
  String status = 'Detected',
  List<String> rooms = const ['Bedroom', 'Kitchen'],
  String? selectedRoom,
  num? score,
  DateTime? updated,
}) {
  final plan = FloorPlanRecord.fromJson({
    'FloorPlanID': 'fp',
    'UserID': 'u',
    'ImagePath': 'u/1.png',
    'Status': 'Uploaded',
    'UploadDateTime': (updated ?? DateTime.now()).toUtc().toIso8601String(),
  });
  final analysis = FloorPlanAnalysisRecord.fromJson({
    'FloorPlanID': 'fp',
    'UserID': 'u',
    'Status': status,
    'DetectionJSON': {
      'rooms': [
        for (final (i, name) in rooms.indexed)
          {'id': 'r$i', 'name': name, 'confidence': 0.9, 'labelDetected': true},
      ],
    },
    'SelectedRoomID': selectedRoom == null
        ? null
        : 'r${rooms.indexOf(selectedRoom)}',
    'SelectedLayoutJSON': score == null
        ? null
        : {
            'layout': {'title': 'T', 'score': score},
          },
    'CreatedAt': (updated ?? DateTime.now()).toUtc().toIso8601String(),
    'UpdatedAt': (updated ?? DateTime.now()).toUtc().toIso8601String(),
  });
  return ProjectSummary.of(plan, analysis);
}

Future<Uint8List> png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final image = await recorder.endRecording().toImage(w, h);
  return (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
}

/// What a project card, Home's totals and the upload area show.
void main() {
  setUpAll(loadRoboto);

  group('the stage chip', () {
    test('is grey until analysed, blue on the way, green when chosen', () {
      expect(statusOfStage(ProjectStage.uploaded), AppStatus.neutral);
      expect(statusOfStage(ProjectStage.detected), AppStatus.info);
      expect(statusOfStage(ProjectStage.layoutReady), AppStatus.info);
      expect(statusOfStage(ProjectStage.layoutSelected), AppStatus.success);
    });

    testWidgets('names the stage', (tester) async {
      for (final stage in ProjectStage.values) {
        await _pump(tester, ProjectStageChip(stage: stage));
        expect(find.text(stage.label), findsOneWidget, reason: '$stage');
      }
    });
  });

  group('Home totals', () {
    testWidgets('show the three counts', (tester) async {
      await _pump(
        tester,
        const ProjectStatsRow(
          stats: ProjectStats(plans: 12, finished: 5, lastScore: 86),
        ),
      );
      expect(find.text('Floor plans uploaded'), findsOneWidget);
      expect(find.text('Finished plans'), findsOneWidget);
      expect(find.text('Last layout score'), findsOneWidget);
      expect(find.textContaining('12'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);
      expect(find.textContaining('86'), findsOneWidget);
      expect(find.textContaining('/100'), findsOneWidget);
    });

    testWidgets('show a dash until a layout has been chosen', (tester) async {
      await _pump(
        tester,
        const ProjectStatsRow(
          stats: ProjectStats(plans: 1, finished: 0, lastScore: null),
        ),
      );
      expect(find.text('–'), findsOneWidget);
      expect(find.textContaining('/100'), findsNothing);
    });

    testWidgets(
      'work inside the scrolling column on Home, which has no height',
      (tester) async {
        await _pump(
          tester,
          const SingleChildScrollView(
            child: Column(
              children: [
                ProjectStatsRow(
                  stats: ProjectStats(plans: 3, finished: 1, lastScore: 74),
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Finished plans'), findsOneWidget);
      },
    );

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      for (final (themeName, theme) in [
        ('dark', AppTheme.darkTheme()),
        ('light', AppTheme.lightTheme()),
      ]) {
        testWidgets('fit a $name screen in $themeName, even with big numbers', (
          tester,
        ) async {
          await _pump(
            tester,
            const Padding(
              padding: EdgeInsets.all(16),
              child: ProjectStatsRow(
                stats: ProjectStats(
                  plans: 12345,
                  finished: 9876,
                  lastScore: 100,
                ),
              ),
            ),
            size: size,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('a project card', () {
    Widget card(
      ProjectSummary s, {
      VoidCallback? onTap,
      double width = 158,
      double height = 214,
    }) => SizedBox(
      width: width,
      height: height,
      child: projectCardForTest(s, onTap: onTap),
    );

    testWidgets('tells where the plan is and what to do next', (tester) async {
      await _pump(tester, card(summary(status: 'Detected')));
      expect(find.text('Rooms detected'), findsOneWidget);
      expect(find.text('Floor plan with 2 rooms'), findsOneWidget);
      expect(find.text('Pick a room'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('shows every stage\'s next step', (tester) async {
      for (final (status, label, next) in const [
        ('Detected', 'Rooms detected', 'Pick a room'),
        ('LayoutReady', 'Layouts ready', 'Compare layouts'),
        ('LayoutSelected', 'Layout chosen', 'Open layouts'),
      ]) {
        await _pump(tester, card(summary(status: status)));
        expect(find.text(label), findsOneWidget, reason: status);
        expect(find.text(next), findsOneWidget, reason: status);
      }
    });

    testWidgets('is named for the room taken forward, with its score', (
      tester,
    ) async {
      await _pump(
        tester,
        card(
          summary(
            status: 'LayoutSelected',
            selectedRoom: 'Kitchen',
            score: 86.4,
          ),
        ),
      );
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('86'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
    });

    testWidgets('has no score until a layout is chosen', (tester) async {
      await _pump(tester, card(summary(status: 'LayoutReady')));
      expect(find.text('/100'), findsNothing);
    });

    testWidgets('a plan with no analysis says to upload again', (tester) async {
      final plan = FloorPlanRecord.fromJson({
        'FloorPlanID': 'fp',
        'UserID': 'u',
        'ImagePath': 'u/1.png',
        'Status': 'Uploaded',
        'UploadDateTime': DateTime.now().toUtc().toIso8601String(),
      });
      await _pump(tester, card(ProjectSummary.of(plan, null)));
      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.text('Floor plan'), findsOneWidget);
      expect(find.text('Upload again to analyse'), findsOneWidget);
    });

    testWidgets('opens when tapped', (tester) async {
      var taps = 0;
      await _pump(tester, card(summary(), onTap: () => taps++));
      await tester.tap(find.text('Pick a room'));
      expect(taps, 1);
    });

    testWidgets('keeps its layout with a long name, on the narrowest card', (
      tester,
    ) async {
      await _pump(
        tester,
        card(
          summary(
            status: 'LayoutSelected',
            rooms: ['A very long room name that cannot possibly fit on a card'],
            selectedRoom:
                'A very long room name that cannot possibly fit on a card',
            score: 100,
          ),
          width: 140,
          height: 190,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to a sketch when the image cannot load', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 158,
          height: 214,
          child: projectCardForTest(
            summary(),
            imageUrl: 'http://localhost:1/x.png',
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Pick a room'), findsOneWidget);
    });

    for (final (themeName, theme) in [
      ('dark', AppTheme.darkTheme()),
      ('light', AppTheme.lightTheme()),
    ]) {
      testWidgets('fits in $themeName for every stage', (tester) async {
        for (final status in [
          'Uploaded',
          'Detected',
          'LayoutReady',
          'LayoutSelected',
        ]) {
          await _pump(
            tester,
            card(
              summary(
                status: status,
                score: status == 'LayoutSelected' ? 91 : null,
              ),
            ),
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: '$themeName $status');
        }
      });
    }
  });

  group('the upload area', () {
    testWidgets('invites a choice before one is made', (tester) async {
      await _pump(tester, uploadDropzoneForTest());
      expect(find.text('Upload your floor plan'), findsOneWidget);
      expect(find.text('Choose image'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the chosen image before it is uploaded', (tester) async {
      final bytes = await tester.runAsync(() => png(600, 400));
      await _pump(
        tester,
        SingleChildScrollView(
          child: uploadDropzoneForTest(
            selected: true,
            fileName: 'plan.png',
            previewBytes: bytes,
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Floor plan selected'), findsOneWidget);
      expect(find.text('plan.png'), findsOneWidget);
      expect(find.text('Choose a different image'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Preview of your floor plan'),
        findsOneWidget,
      );
    });

    testWidgets('an unreadable image shows a placeholder, not an error', (
      tester,
    ) async {
      await _pump(
        tester,
        SingleChildScrollView(
          child: uploadDropzoneForTest(
            selected: true,
            fileName: 'broken.png',
            previewBytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      expect(find.text('broken.png'), findsOneWidget);
    });

    testWidgets('choosing again calls back', (tester) async {
      var picks = 0;
      await _pump(tester, uploadDropzoneForTest(onSelect: () => picks++));
      await tester.tap(find.text('Choose image'));
      expect(picks, 1);
    });

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      testWidgets('fits a $name screen with a wide and a tall image', (
        tester,
      ) async {
        final wide = await tester.runAsync(() => png(1600, 300));
        final tall = await tester.runAsync(() => png(300, 1600));
        for (final bytes in [wide, tall]) {
          await _pump(
            tester,
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: uploadDropzoneForTest(
                  selected: true,
                  fileName: 'plan.png',
                  previewBytes: bytes,
                ),
              ),
            ),
            size: size,
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
