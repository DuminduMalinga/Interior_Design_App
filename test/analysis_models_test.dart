import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';

/// Parses the web pipeline's JSON. `fixtures/living_room_layouts.json` is real
/// output of the web repo's living-room layout engine (room_medium scenario),
/// so these tests catch drift between the two apps' data contracts.
void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/living_room_layouts.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('AnalysisLayoutSet', () {
    test('parses layouts, best pick and sorts by score', () {
      final set = AnalysisLayoutSet.from(fixture)!;
      expect(set.roomId, 'room-2');
      expect(set.bestType, fixture['bestLayout']);
      expect(set.layouts, isNotEmpty);
      for (var i = 1; i < set.layouts.length; i++) {
        expect(set.layouts[i - 1].score >= set.layouts[i].score, isTrue);
      }
    });

    test('reads room size in mm, furniture boxes and openings', () {
      final layout = AnalysisLayoutSet.from(fixture)!.layouts.first;
      expect(layout.roomWidth, greaterThan(1000));
      expect(layout.roomLength, greaterThan(1000));
      expect(layout.furniture, isNotEmpty);
      for (final f in layout.furniture) {
        expect(f.x1, greaterThan(f.x0));
        expect(f.y1, greaterThan(f.y0));
        // Furniture sits inside the room.
        expect(f.x0, greaterThanOrEqualTo(-1));
        expect(f.x1, lessThanOrEqualTo(layout.roomWidth + 1));
      }
      expect(layout.openings.any((o) => o.isDoor), isTrue);
      expect(layout.reasons, isNotEmpty);
      expect(layout.components, isNotEmpty);
    });

    test('keeps the raw document so it can be saved back unchanged', () {
      final layout = AnalysisLayoutSet.from(fixture)!.layouts.first;
      expect(layout.raw['layout'], isA<Map>());
      expect(layout.raw['furniture'], isA<List>());
    });

    test('returns null when there are no layouts', () {
      expect(AnalysisLayoutSet.from(null), isNull);
      expect(AnalysisLayoutSet.from({'layouts': []}), isNull);
    });

    test('flags layouts the engine failed to produce', () {
      final set = AnalysisLayoutSet.from({
        'roomId': 'r',
        'layouts': [
          {
            'layout': {'type': 'reading', 'title': 'Reading', 'score': 0},
            'error': 'boom',
          },
        ],
      })!;
      expect(set.layouts.single.hasError, isTrue);
    });
  });

  group('AnalysisRoom', () {
    final detection = {
      'rooms': [
        {
          'id': 'room-2',
          'name': 'Living Room',
          'fallbackName': 'Room 2',
          'labelDetected': true,
          'confidence': 0.93,
          'widthM': 5.0,
          'heightM': 4.0,
          'areaM2': 20.0,
          'bboxPct': {'x': 10, 'y': 20, 'w': 30, 'h': 40},
        },
        {
          'id': 'room-3',
          'name': '',
          'fallbackName': 'Room 3',
          'confidence': 0.8,
          'widthM': null,
          'heightM': null,
          'areaM2': null,
        },
      ],
    };

    test('parses rooms, bbox fractions and the living-room check', () {
      final rooms = AnalysisRoom.listFrom(detection);
      expect(rooms, hasLength(2));
      expect(rooms[0].isLivingRoom, isTrue);
      expect(rooms[0].bboxFraction!.left, closeTo(0.10, 1e-9));
      expect(rooms[0].bboxFraction!.height, closeTo(0.40, 1e-9));
      expect(rooms[0].areaM2, 20.0);
    });

    test('falls back to the auto name and tolerates missing sizes', () {
      final room = AnalysisRoom.listFrom(detection)[1];
      expect(room.name, 'Room 3');
      expect(room.isLivingRoom, isFalse);
      expect(room.areaM2, isNull);
      expect(room.bboxFraction, isNull);
    });

    test('empty for missing or malformed detection json', () {
      expect(AnalysisRoom.listFrom(null), isEmpty);
      expect(AnalysisRoom.listFrom({'rooms': 'x'}), isEmpty);
    });
  });

  group('FloorPlanAnalysisRecord status', () {
    FloorPlanAnalysisRecord record(String status) => FloorPlanAnalysisRecord(
      floorPlanId: 'f',
      userId: 'u',
      detectionJson: null,
      status: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('web statuses count as ready', () {
      for (final s in [
        'Detected',
        'LayoutReady',
        'LayoutSelected',
        'Completed',
      ]) {
        expect(record(s).isComplete, isTrue, reason: s);
      }
      expect(record('Processing').isComplete, isFalse);
      expect(record('Failed').isFailed, isTrue);
    });
  });
}
