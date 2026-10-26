import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/data/plan_geometry.dart';

/// Where rooms sit on the plan image, and how a stored detection is read.
void main() {
  // A 4-wide, 2-tall rectangle and an L made from it.
  const square = [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)];
  const lShape = [
    Offset(0, 0),
    Offset(1, 0),
    Offset(1, 0.4),
    Offset(0.4, 0.4),
    Offset(0.4, 1),
    Offset(0, 1),
  ];

  group('polygonContains', () {
    test('is true inside and false outside a rectangle', () {
      expect(polygonContains(square, const Offset(0.5, 0.5)), isTrue);
      expect(polygonContains(square, const Offset(1.5, 0.5)), isFalse);
      expect(polygonContains(square, const Offset(0.5, -0.1)), isFalse);
    });

    test('follows an L shape: its notch is outside', () {
      expect(polygonContains(lShape, const Offset(0.8, 0.2)), isTrue);
      expect(polygonContains(lShape, const Offset(0.2, 0.8)), isTrue);
      expect(polygonContains(lShape, const Offset(0.8, 0.8)), isFalse);
    });

    test('a line or a point is no room', () {
      expect(
        polygonContains(const [Offset(0, 0), Offset(1, 1)], Offset.zero),
        isFalse,
      );
      expect(polygonContains(const [], Offset.zero), isFalse);
    });

    test('does not care which way round the corners go', () {
      final reversed = square.reversed.toList();
      expect(polygonContains(reversed, const Offset(0.5, 0.5)), isTrue);
    });
  });

  test('polygonArea measures a rectangle and an L, whatever the winding', () {
    expect(polygonArea(square), closeTo(1, 1e-9));
    expect(polygonArea(square.reversed.toList()), closeTo(1, 1e-9));
    expect(polygonArea(lShape), closeTo(1 - 0.6 * 0.6, 1e-9));
    expect(polygonArea(const []), 0);
  });

  test('outlineCentre is the middle of the bounding box', () {
    expect(outlineCentre(lShape), const Offset(0.5, 0.5));
  });

  group('outlineLabelPoint', () {
    test('is the middle of a plain rectangle', () {
      final p = outlineLabelPoint(square);
      expect(p.dx, closeTo(0.5, 1e-9));
      expect(p.dy, closeTo(0.5, 1e-9));
    });

    test('stays inside an L, whose bounding-box centre is in the notch', () {
      // the box's centre (0.5, 0.5) is outside this L
      expect(polygonContains(lShape, const Offset(0.5, 0.5)), isFalse);
      expect(polygonContains(lShape, outlineLabelPoint(lShape)), isTrue);
    });

    test('stays inside a U, whose balance point is in the gap', () {
      const u = [
        Offset(0, 0),
        Offset(0.3, 0),
        Offset(0.3, 0.7),
        Offset(0.7, 0.7),
        Offset(0.7, 0),
        Offset(1, 0),
        Offset(1, 1),
        Offset(0, 1),
      ];
      expect(polygonContains(u, outlineLabelPoint(u)), isTrue);
      // an upside-down U: both arms reach the bottom, the gap is between them
      const arch = [
        Offset(0, 0),
        Offset(1, 0),
        Offset(1, 1),
        Offset(0.7, 1),
        Offset(0.7, 0.3),
        Offset(0.3, 0.3),
        Offset(0.3, 1),
        Offset(0, 1),
      ];
      expect(polygonContains(arch, outlineLabelPoint(arch)), isTrue);
    });

    test('never fails on a line or an empty outline', () {
      expect(() => outlineLabelPoint(const []), returnsNormally);
      expect(
        outlineLabelPoint(const [Offset(0, 0), Offset(1, 1)]),
        const Offset(0.5, 0.5),
      );
    });
  });

  test('rectCorners goes clockwise from the top left', () {
    expect(rectCorners(const Rect.fromLTRB(0.1, 0.2, 0.5, 0.6)), const [
      Offset(0.1, 0.2),
      Offset(0.5, 0.2),
      Offset(0.5, 0.6),
      Offset(0.1, 0.6),
    ]);
  });

  group('roomAt', () {
    test('finds the room a tap landed in, or none', () {
      final left = [for (final p in square) Offset(p.dx * 0.5, p.dy)];
      final right = [for (final p in square) Offset(0.5 + p.dx * 0.5, p.dy)];
      expect(roomAt([left, right], const Offset(0.2, 0.5)), 0);
      expect(roomAt([left, right], const Offset(0.8, 0.5)), 1);
      expect(roomAt([left, right], const Offset(1.2, 0.5)), isNull);
      expect(roomAt(const [], const Offset(0.5, 0.5)), isNull);
    });

    test('a tap in the L\'s notch reaches the room beside it, not the L', () {
      final inNotch = [
        const Offset(0.5, 0.5),
        const Offset(1, 0.5),
        const Offset(1, 1),
        const Offset(0.5, 1),
      ];
      expect(roomAt([lShape, inNotch], const Offset(0.8, 0.8)), 1);
    });

    test('where outlines overlap, the smaller room wins', () {
      final big = [for (final p in square) p];
      final small = [
        const Offset(0.4, 0.4),
        const Offset(0.6, 0.4),
        const Offset(0.6, 0.6),
        const Offset(0.4, 0.6),
      ];
      expect(roomAt([big, small], const Offset(0.5, 0.5)), 1);
      expect(roomAt([small, big], const Offset(0.5, 0.5)), 0);
    });
  });

  group('reading a stored detection', () {
    // Field names as the wall detector stores them in DetectionJSON.
    Map<String, dynamic> room({
      String id = 'room-1',
      Object? polygonPct,
      Object? bboxPct,
      double? widthM,
      double? heightM,
      double? areaM2,
      String? areaSource,
      double widthPx = 400,
      double heightPx = 300,
      double areaPx = 100000,
    }) => {
      'id': id,
      'name': 'Bedroom',
      'confidence': 0.9689,
      'labelDetected': true,
      'widthM': widthM,
      'heightM': heightM,
      'areaM2': areaM2,
      'areaSource': areaSource,
      'widthPx': widthPx,
      'heightPx': heightPx,
      'areaPx': areaPx,
      'bboxPct': bboxPct,
      'polygonPct': polygonPct,
    };

    Map<String, dynamic> detection(
      List<Map<String, dynamic>> rooms, {
      List<double> doorSpans = const [],
    }) => {
      'imageWidth': 1312,
      'imageHeight': 1199,
      'counts': {'Wall': 31, 'Room': rooms.length, 'Door': 4, 'Window': 5},
      'detections': [
        for (final s in doorSpans)
          {
            'class': 'Door',
            'bbox': {'x1': 10.0, 'y1': 10.0, 'x2': 10.0 + s, 'y2': 14.0},
          },
        {
          'class': 'Window',
          'bbox': {'x1': 0.0, 'y1': 0.0, 'x2': 500.0, 'y2': 2.0},
        },
      ],
      'rooms': rooms,
    };

    test('turns the outline from percent into fractions of the image', () {
      final plan = AnalysisPlan.from(
        detection([
          room(
            polygonPct: [
              [10, 50],
              [40, 50],
              [40, 90],
              [10, 90],
            ],
          ),
        ]),
      );
      expect(plan.rooms.single.outline, const [
        Offset(0.1, 0.5),
        Offset(0.4, 0.5),
        Offset(0.4, 0.9),
        Offset(0.1, 0.9),
      ]);
    });

    test('falls back to the box when the room has no outline', () {
      final plan = AnalysisPlan.from(
        detection([
          room(bboxPct: {'x': 10.0, 'y': 20.0, 'w': 30.0, 'h': 40.0}),
        ]),
      );
      final outline = plan.rooms.single.outline!;
      expect(outline.first.dx, closeTo(0.1, 1e-9));
      expect(outline.first.dy, closeTo(0.2, 1e-9));
      expect(outline[2].dx, closeTo(0.4, 1e-9));
      expect(outline[2].dy, closeTo(0.6, 1e-9));
    });

    test('has no position when the detection recorded none', () {
      expect(
        AnalysisPlan.from(detection([room()])).rooms.single.outline,
        isNull,
      );
    });

    test('ignores an outline that is not a real shape', () {
      for (final bad in [
        [
          [10, 10],
          [20, 20],
        ],
        [
          [10, 10],
          ['x', 20],
          [30, 30],
        ],
        [
          [10],
          [20, 20],
          [30, 30],
        ],
        'junk',
      ]) {
        final r = AnalysisPlan.from(
          detection([room(polygonPct: bad)]),
        ).rooms.single;
        expect(r.polygonFraction, isNull, reason: '$bad');
      }
    });

    test('knows the plan image\'s shape and the counts', () {
      final plan = AnalysisPlan.from(detection([room()]));
      expect(plan.aspectRatio, closeTo(1312 / 1199, 1e-9));
      expect(plan.counts, {'Wall': 31, 'Room': 1, 'Door': 4, 'Window': 5});
    });

    test('is 4:3 until it knows the image size', () {
      expect(
        AnalysisPlan.from({'rooms': []}).aspectRatio,
        closeTo(4 / 3, 1e-9),
      );
    });

    test('anything that is not a detection is an empty plan', () {
      for (final junk in [null, 'x', 5, <Object>[]]) {
        final plan = AnalysisPlan.from(junk);
        expect(plan.rooms, isEmpty);
        expect(plan.counts, isEmpty);
      }
    });

    group('room size', () {
      test('uses the size printed on the plan, and says so', () {
        final plan = AnalysisPlan.from(
          detection([
            room(widthM: 4.2, heightM: 3.1, areaM2: 13.0, areaSource: 'ocr'),
          ]),
        );
        final size = plan.sizeOf(plan.rooms.single)!;
        expect(size.dims, '4.20 × 3.10 m');
        expect(size.area, '13.0 m²');
        expect(size.note, "from the plan's printed area");
      });

      test('estimates from the doors, taking a standard 900 mm door', () {
        // spans 60, 80, 90 px: the middle one, 80 px, is a 900 mm door
        final plan = AnalysisPlan.from(
          detection([room()], doorSpans: [90, 60, 80]),
        );
        expect(plan.scaleSource, 'door');
        expect(plan.mmPerPx, closeTo(900 / 80, 1e-9));
        final size = plan.sizeOf(plan.rooms.single)!;
        expect(size.widthM, closeTo(400 * 0.01125, 1e-9));
        expect(size.heightM, closeTo(300 * 0.01125, 1e-9));
        expect(size.areaM2, closeTo(100000 * 0.01125 * 0.01125, 1e-9));
        expect(size.note, contains('standard 900 mm door'));
      });

      test('falls back to 20 mm a pixel when there are no doors', () {
        final plan = AnalysisPlan.from(detection([room()]));
        expect(plan.scaleSource, 'default');
        expect(plan.mmPerPx, 20);
        final size = plan.sizeOf(plan.rooms.single)!;
        expect(size.widthM, closeTo(8, 1e-9));
        expect(size.note, startsWith('a rough estimate'));
      });

      test('a half-printed size is not trusted: it is estimated instead', () {
        final plan = AnalysisPlan.from(
          detection([room(widthM: 4.2, areaSource: 'ocr')]),
        );
        expect(plan.sizeOf(plan.rooms.single)!.note, startsWith('a rough'));
      });

      test('has no size when the detection holds neither', () {
        const room = AnalysisRoom(
          id: 'r',
          name: 'Room',
          confidence: 1,
          labelDetected: false,
        );
        expect(AnalysisPlan.from({'rooms': []}).sizeOf(room), isNull);
      });

      test('a size with no recorded source has no note', () {
        final plan = AnalysisPlan.from(
          detection([room(widthM: 4, heightM: 3, areaM2: 12)]),
        );
        expect(plan.sizeOf(plan.rooms.single)!.note, isNull);
      });

      test('every source has a note, as the web has', () {
        for (final source in ['ocr', 'estimated', 'door', 'default']) {
          expect(
            RoomSize(widthM: 1, heightM: 1, areaM2: 1, source: source).note,
            isNotNull,
            reason: source,
          );
        }
      });
    });
  });
}
