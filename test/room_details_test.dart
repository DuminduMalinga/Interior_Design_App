import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/main.dart';
import 'package:interior_design/room_details.dart';

import 'test_utils.dart';

/// A bedroom layout as the engine stores it (field names from LayoutJSON).
Map<String, dynamic> layoutJson({
  bool valid = true,
  double score = 99.2,
  double? area = 13.0,
  List<Map<String, dynamic>>? furniture,
}) => {
  'layout': {
    'type': 'bed_west',
    'title': 'Bed on the west wall',
    'score': score,
    'suitability_score': 91.0,
  },
  'room': {
    'width': 4200,
    'length': 3100,
    'height': 2800,
    'area_m2': ?area,
    'cutouts': <List<num>>[],
  },
  'validation': {'valid': valid, 'notes': <String>[]},
  'openings': {
    'doors': <Map<String, dynamic>>[],
    'windows': <Map<String, dynamic>>[],
  },
  'furniture':
      furniture ??
      [
        {
          'id': 'bed-1',
          'type': 'bed',
          'label': 'Double bed',
          'bbox': [0, 800, 2000, 2200],
          'width': 2000,
          'depth': 1400,
          'height': 600,
          'facing': 'east',
          'placement_strategy': 'headboard:west_wall',
          'reasons': [
            'The headboard is against the west wall.',
            'Both sides have 600 mm to get in and out.',
          ],
          'role': 'bed',
        },
        {
          'id': 'lamp-1',
          'type': 'bedside_lamp',
          'bbox': [0, 300, 300, 600],
          'height': 450,
          'facing': 'south',
        },
      ],
};

AnalysisLayout layout({
  bool valid = true,
  double score = 99.2,
  double? area = 13.0,
  List<Map<String, dynamic>>? furniture,
}) => AnalysisLayout.fromJson(
  layoutJson(valid: valid, score: score, area: area, furniture: furniture),
);

const _sizes = {
  'mobile': Size(360, 740),
  'tablet': Size(800, 900),
  'desktop': Size(1440, 900),
};

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  Size size, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: theme ?? AppTheme.darkTheme(), home: home),
  );
  await tester.pump();
}

/// What the 3D view's side panel tells about a layout (the web's RoomView3D).
void main() {
  setUpAll(loadRoboto);

  group('reading a piece the engine placed', () {
    test('keeps its label, how it was placed and why', () {
      final bed = layout().furniture.first;
      expect(bed.engineLabel, 'Double bed');
      expect(bed.placementStrategy, 'headboard:west_wall');
      expect(bed.reasons, [
        'The headboard is against the west wall.',
        'Both sides have 600 mm to get in and out.',
      ]);
      expect(bed.width, 2000);
      expect(bed.depth, 1400);
      expect(bed.displayName, 'Double bed');
    });

    test('works out its size from its box when the engine gave none', () {
      final lamp = layout().furniture.last;
      expect(lamp.width, 300);
      expect(lamp.depth, 300);
      expect(lamp.reasons, isEmpty);
      expect(lamp.placementStrategy, isNull);
    });

    test('is named by label, else role, else type, in plain words', () {
      AnalysisFurniture piece(Map<String, dynamic> extra) =>
          AnalysisFurniture.fromJson({
            'id': 'x',
            'type': 'coffee_table',
            'bbox': [0, 0, 1, 1],
            ...extra,
          });
      expect(
        piece({'label': 'Round table', 'role': 'r'}).displayName,
        'Round table',
      );
      expect(piece({'role': 'prep counter'}).displayName, 'Prep counter');
      expect(piece({}).displayName, 'Coffee table');
      expect(
        piece({'label': '  ', 'role': 'wall_shelf'}).displayName,
        'Wall shelf',
      );
    });

    test('ignores blank reasons', () {
      final f = AnalysisFurniture.fromJson({
        'id': 'x',
        'type': 'sofa',
        'bbox': [0, 0, 1, 1],
        'reasons': ['  ', 'Faces the TV.', 5, ''],
      });
      expect(f.reasons, ['Faces the TV.']);
    });
  });

  group('the room\'s area', () {
    test('is the engine\'s, which an L-shaped room needs', () {
      expect(layout(area: 10.5).areaM2, 10.5);
    });

    test('is width x length when the engine gave none', () {
      expect(layout(area: null).areaM2, closeTo(4.2 * 3.1, 1e-9));
    });
  });

  group('wording', () {
    test('fmtMm writes metres to two places, as the web does', () {
      expect(fmtMm(1850), '1.85m');
      expect(fmtMm(600), '0.60m');
      expect(fmtMm(2800), '2.80m');
    });

    test('a placement note reads as words', () {
      expect(prettyStrategy('headboard:west_wall'), 'Headboard · west wall');
      expect(prettyStrategy('against_wall'), 'Against wall');
      expect(prettyStrategy(null), isNull);
      expect(prettyStrategy('  '), isNull);
    });

    test('a facing starts with a capital', () {
      expect(capitalised('south'), 'South');
      expect(capitalised(''), '');
    });
  });

  group('RoomDetailsPanel', () {
    Widget panel(
      AnalysisLayout l, {
      String? selected,
      ValueChanged<String?>? onSelect,
    }) => Scaffold(
      body: RoomDetailsPanel(
        layout: l,
        selectedId: selected,
        onSelect: onSelect ?? (_) {},
        colorFor: (_) => Colors.teal,
      ),
    );

    testWidgets('shows the score, the room and what is in it', (tester) async {
      await _pump(tester, panel(layout()), _sizes['mobile']!);
      expect(find.text('Layout score'), findsOneWidget);
      expect(find.text('99'), findsOneWidget);
      expect(find.text('Valid layout'), findsOneWidget);
      expect(find.text('4.20 × 3.10 m'), findsOneWidget);
      expect(find.text('13 m²'), findsOneWidget);
      expect(find.text('2.80m'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // pieces
      expect(find.text('In this room'), findsOneWidget);
      expect(find.text('Double bed'), findsOneWidget);
      expect(find.text('Bedside lamp'), findsOneWidget);
      expect(find.text('2.00m × 1.40m'), findsOneWidget);
    });

    testWidgets('rounds the score and trims the area like the web', (
      tester,
    ) async {
      await _pump(
        tester,
        panel(layout(score: 86.5, area: 13.456)),
        _sizes['mobile']!,
      );
      expect(find.text('87'), findsOneWidget);
      expect(find.text('13.46 m²'), findsOneWidget);
    });

    testWidgets('says when the layout is compromised', (tester) async {
      await _pump(tester, panel(layout(valid: false)), _sizes['mobile']!);
      expect(find.text('Compromised'), findsOneWidget);
      expect(find.text('Valid layout'), findsNothing);
    });

    testWidgets('picking a piece reports its id', (tester) async {
      final picked = <String?>[];
      await _pump(
        tester,
        panel(layout(), onSelect: picked.add),
        _sizes['mobile']!,
      );
      await tester.tap(find.text('Double bed'));
      expect(picked, ['bed-1']);
    });

    testWidgets('a picked piece shows what it is and why it is there', (
      tester,
    ) async {
      await _pump(
        tester,
        panel(layout(), selected: 'bed-1'),
        _sizes['mobile']!,
      );
      expect(find.text('All pieces'), findsOneWidget);
      expect(find.text('Double bed'), findsOneWidget);
      expect(find.text('2.00m × 1.40m'), findsOneWidget);
      expect(find.text('0.60m'), findsOneWidget); // height
      expect(find.text('East'), findsOneWidget);
      expect(find.text('Headboard · west wall'), findsOneWidget);
      expect(find.text('Why it is here'), findsOneWidget);
      expect(
        find.text('The headboard is against the west wall.'),
        findsOneWidget,
      );
      expect(find.text('In this room'), findsNothing);
    });

    testWidgets('a piece with no reasons or note says so plainly', (
      tester,
    ) async {
      await _pump(
        tester,
        panel(layout(), selected: 'lamp-1'),
        _sizes['mobile']!,
      );
      expect(find.text('Not recorded'), findsOneWidget);
      expect(find.text('Why it is here'), findsNothing);
    });

    testWidgets('going back to all pieces reports null', (tester) async {
      final picked = <String?>[];
      await _pump(
        tester,
        panel(layout(), selected: 'bed-1', onSelect: picked.add),
        _sizes['mobile']!,
      );
      await tester.tap(find.text('All pieces'));
      expect(picked, [null]);
    });

    testWidgets(
      'an id that is no longer in the layout falls back to the list',
      (tester) async {
        await _pump(
          tester,
          panel(layout(), selected: 'gone'),
          _sizes['mobile']!,
        );
        expect(find.text('In this room'), findsOneWidget);
        expect(find.text('All pieces'), findsNothing);
      },
    );

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      for (final (themeName, theme) in [
        ('dark', AppTheme.darkTheme()),
        ('light', AppTheme.lightTheme()),
      ]) {
        testWidgets('fits a $name screen in $themeName', (tester) async {
          for (final selected in [null, 'bed-1']) {
            await _pump(
              tester,
              panel(layout(), selected: selected),
              size,
              theme: theme,
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });

  group('the viewer', () {
    Future<void> open(
      WidgetTester tester, {
      required Size size,
      AnalysisLayout? withLayout,
      bool legacy = false,
    }) => _pump(
      tester,
      roomViewerForTest(
        roomName: 'Bedroom',
        layout: legacy ? null : (withLayout ?? layout()),
      ),
      size,
    );

    testWidgets('a phone opens the details over the room, and hides them', (
      tester,
    ) async {
      await open(tester, size: _sizes['mobile']!);
      expect(find.text('Layout score'), findsNothing);
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Layout score'), findsOneWidget);
      expect(find.text('In this room'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      await tester.tap(find.text('Hide'));
      await tester.pumpAndSettle();
      expect(find.text('Layout score'), findsNothing);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('a phone can pick a piece and come back to the list', (
      tester,
    ) async {
      await open(tester, size: _sizes['mobile']!);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Double bed'));
      await tester.pumpAndSettle();
      expect(find.text('Why it is here'), findsOneWidget);
      await tester.tap(find.text('All pieces'));
      await tester.pumpAndSettle();
      expect(find.text('In this room'), findsOneWidget);
    });

    for (final name in ['tablet', 'desktop']) {
      testWidgets('a $name keeps the details beside the room', (tester) async {
        await open(tester, size: _sizes[name]!);
        expect(find.text('Layout score'), findsOneWidget);
        expect(find.text('In this room'), findsOneWidget);
        // always there, so there is nothing to toggle
        expect(find.text('Details'), findsNothing);
        expect(find.text('Hide'), findsNothing);

        await tester.tap(find.text('Double bed'));
        await tester.pumpAndSettle();
        expect(
          find.text('The headboard is against the west wall.'),
          findsOneWidget,
        );
      });
    }

    testWidgets('export and share are still there', (tester) async {
      await open(tester, size: _sizes['mobile']!);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('the inert Edit button is gone', (tester) async {
      await open(tester, size: _sizes['mobile']!);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('a layout from the older pipeline has no details', (
      tester,
    ) async {
      await open(tester, size: _sizes['mobile']!, legacy: true);
      expect(find.text('Details'), findsNothing);
      await open(tester, size: _sizes['desktop']!, legacy: true);
      expect(find.text('Layout score'), findsNothing);
    });

    testWidgets('reset view is on the rail, and works after a zoom', (
      tester,
    ) async {
      await open(tester, size: _sizes['mobile']!);
      await tester.tap(find.byIcon(Icons.zoom_in_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Reset view'), findsOneWidget);
    });

    testWidgets('outlining a piece in the room does not throw, for any kind', (
      tester,
    ) async {
      final everyKind = layout(
        furniture: [
          {
            'id': 'a',
            'type': 'sofa',
            'bbox': [200, 200, 1800, 900],
            'height': 800,
          },
          {
            'id': 'b',
            'type': 'mirror',
            'bbox': [100, 0, 700, 40],
            'height': 900,
            'mounted': 'wall',
            'mount_height': 1100,
          },
          {
            'id': 'c',
            'type': 'ceiling_light',
            'bbox': [1000, 1000, 1300, 1300],
            'height': 100,
            'mounted': 'ceiling',
          },
          {
            'id': 'd',
            'type': 'floor_drain',
            'bbox': [2000, 1000, 2100, 1100],
            'height': 10,
            'mounted': 'drain',
          },
          {
            'id': 'e',
            'type': 'l_sofa',
            'bbox': [0, 0, 2000, 1500],
            'height': 800,
            'shape': 'l',
            'parts': [
              [0, 0, 2000, 900],
              [0, 900, 900, 1500],
            ],
          },
        ],
      );
      await open(tester, size: _sizes['desktop']!, withLayout: everyKind);
      for (final name in [
        'Sofa',
        'Mirror',
        'Ceiling light',
        'Floor drain',
        'L sofa',
      ]) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: name);
        await tester.tap(find.text('All pieces'));
        await tester.pumpAndSettle();
      }
    });

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      testWidgets('draws without overflow on a $name screen', (tester) async {
        await open(tester, size: size);
        if (name == 'mobile') {
          await tester.tap(find.text('Details'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Double bed'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
