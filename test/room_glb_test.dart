import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/main.dart';

import 'glb_reader.dart';

/// A bedroom as the engine stores it: 4.2 x 3.1 m, a door on the south wall,
/// a window on the north and one on the east.
AnalysisLayout bedroom({List<Map<String, dynamic>>? extra}) =>
    AnalysisLayout.fromJson({
      'layout': {
        'type': 'bed_west',
        'title': 'Bed',
        'score': 99,
        'suitability_score': 90,
      },
      'room': {
        'width': 4200,
        'length': 3100,
        'height': 2800,
        'area_m2': 13.0,
        'cutouts': <Object>[],
      },
      'validation': {'valid': true},
      'openings': {
        'doors': [
          {'wall': 'south', 'position': 600, 'width': 900},
        ],
        'windows': [
          {
            'wall': 'north',
            'position': 1500,
            'width': 1400,
            'sill_height': 900,
            'height': 1200,
          },
          {
            'wall': 'east',
            'position': 900,
            'width': 1200,
            'sill_height': 900,
            'height': 1200,
          },
        ],
      },
      'furniture': [
        {
          'id': 'bed-1',
          'type': 'bed',
          'label': 'Double bed',
          'bbox': [100, 700, 2100, 2100],
          'width': 2000,
          'depth': 1400,
          'height': 600,
          'facing': 'east',
        },
        {
          'id': 'wd-1',
          'type': 'wardrobe',
          'bbox': [3000, 2400, 4100, 3000],
          'height': 2100,
          'facing': 'north',
        },
        {
          'id': 'bt-1',
          'type': 'bedside_table',
          'bbox': [100, 300, 500, 700],
          'height': 450,
          'facing': 'east',
        },
        ...?extra,
      ],
    });

/// A 3 x 2.4 m bathroom with a corner cut away (an L), a door and a window.
AnalysisLayout lBathroom() => AnalysisLayout.fromJson({
  'layout': {
    'type': 'bath',
    'title': 'Bath',
    'score': 90,
    'suitability_score': 80,
  },
  'room': {
    'width': 3000,
    'length': 2400,
    'height': 2600,
    'cutouts': [
      [1800, 1400, 3000, 2400],
    ],
  },
  'validation': {'valid': true},
  'openings': {
    'doors': [
      {'wall': 'south', 'position': 300, 'width': 800},
    ],
    'windows': [
      {
        'wall': 'west',
        'position': 800,
        'width': 600,
        'sill_height': 1200,
        'height': 700,
      },
    ],
  },
  'furniture': [
    {
      'id': 't',
      'type': 'toilet',
      'bbox': [100, 100, 500, 700],
      'height': 420,
      'facing': 'north',
    },
    {
      'id': 's',
      'type': 'shower',
      'bbox': [100, 1200, 1000, 2100],
      'height': 2000,
      'facing': 'east',
    },
  ],
});

/// An axis-aligned block in glTF space (x, up, z).
typedef Box = ({
  double x0,
  double x1,
  double y0,
  double y1,
  double z0,
  double z1,
});

/// Every block (24 vertices each) of the node called [name].
List<Box> boxesOf(Glb g, String name) {
  final boxes = <Box>[];
  for (final prim in g.primitives(name)) {
    for (var v = 0; v + 72 <= prim.p.length; v += 72) {
      double lo(int axis) => [
        for (var k = 0; k < 24; k++) prim.p[v + k * 3 + axis].toDouble(),
      ].reduce(math.min);
      double hi(int axis) => [
        for (var k = 0; k < 24; k++) prim.p[v + k * 3 + axis].toDouble(),
      ].reduce(math.max);
      boxes.add((
        x0: lo(0),
        x1: hi(0),
        y0: lo(1),
        y1: hi(1),
        z0: lo(2),
        z1: hi(2),
      ));
    }
  }
  return boxes;
}

bool inside(Box b, double x, double y, double z) =>
    x > b.x0 && x < b.x1 && y > b.y0 && y < b.y1 && z > b.z0 && z < b.z1;

bool anyInside(List<Box> boxes, double x, double y, double z) =>
    boxes.any((b) => inside(b, x, y, z));

/// The bounds of a whole node.
Box boundsOf(Glb g, String name) {
  final b = boxesOfAny(g, name);
  return (
    x0: b.map((e) => e.x0).reduce(math.min),
    x1: b.map((e) => e.x1).reduce(math.max),
    y0: b.map((e) => e.y0).reduce(math.min),
    y1: b.map((e) => e.y1).reduce(math.max),
    z0: b.map((e) => e.z0).reduce(math.min),
    z1: b.map((e) => e.z1).reduce(math.max),
  );
}

/// The bounding box of each primitive of a node, whatever its shapes.
List<Box> boxesOfAny(Glb g, String name) => [
  for (final prim in g.primitives(name))
    (
      x0: [
        for (var k = 0; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.min),
      x1: [
        for (var k = 0; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.max),
      y0: [
        for (var k = 1; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.min),
      y1: [
        for (var k = 1; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.max),
      z0: [
        for (var k = 2; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.min),
      z1: [
        for (var k = 2; k < prim.p.length; k += 3) prim.p[k].toDouble(),
      ].reduce(math.max),
    ),
];

Glb model(AnalysisLayout a, {String? name}) =>
    Glb(roomToGlb(a, roomName: name));

List<String> names(Glb g) => [
  for (final n in g.list('nodes')) n['name'] as String,
];

/// The 3D model of a room that Export gives: real size, named pieces, and
/// walls with real openings.
void main() {
  group('what it is made of', () {
    test('names the scene after the room', () {
      expect(
        model(bedroom(), name: 'Master bedroom').list('scenes').single['name'],
        'Master bedroom',
      );
      expect(
        model(bedroom()).list('scenes').single['name'],
        'Bed',
        reason: 'else the layout',
      );
    });

    test('has the shell and then each piece of furniture, by name', () {
      expect(names(model(bedroom())), [
        'Floor',
        'Walls',
        'Windows',
        'Doors',
        'Double bed',
        'Wardrobe',
        'Bedside table',
      ]);
    });

    test('keeps each piece\'s id and type with it', () {
      final g = model(bedroom());
      final bed = g.list('nodes').firstWhere((n) => n['name'] == 'Double bed');
      expect(bed['extras'], {'id': 'bed-1', 'type': 'bed'});
    });

    test('draws pieces from the same solids the viewer shows', () {
      final g = model(bedroom());
      // a bed is more than one block: frame, mattress, headboard...
      expect(boxesOfAny(g, 'Double bed').length, greaterThan(1));
    });

    test('leaves out what the viewer does not draw, a ceiling light', () {
      final g = model(
        bedroom(
          extra: [
            {
              'id': 'cl',
              'type': 'ceiling_light',
              'bbox': [1000, 1000, 1300, 1300],
              'height': 100,
              'mounted': 'ceiling',
            },
          ],
        ),
      );
      expect(names(g), isNot(contains('Ceiling light')));
    });
  });

  group('real size, in metres', () {
    test('the floor is exactly the room', () {
      final f = boundsOf(model(bedroom()), 'Floor');
      expect(f.x0, closeTo(0, 1e-4));
      expect(f.x1, closeTo(4.2, 1e-4));
      expect(f.z0, closeTo(-3.1, 1e-4), reason: 'north is -z');
      expect(f.z1, closeTo(0, 1e-4));
      expect(f.y1, closeTo(0, 1e-4), reason: 'its top is the ground');
      expect(f.y0, closeTo(-0.05, 1e-4));
    });

    test('the walls stand outside the room, to the ceiling', () {
      final w = boundsOf(model(bedroom()), 'Walls');
      expect(w.y1, closeTo(2.8, 1e-4));
      expect(w.x0, closeTo(-0.1, 1e-4));
      expect(w.x1, closeTo(4.3, 1e-4));
      expect(w.z0, closeTo(-3.2, 1e-4));
      expect(w.z1, closeTo(0.1, 1e-4));
    });

    test('a different ceiling height changes the walls', () {
      final tall = bedroom();
      final json = Map<String, dynamic>.from(tall.raw);
      (json['room'] as Map)['height'] = 3500;
      expect(
        boundsOf(model(AnalysisLayout.fromJson(json)), 'Walls').y1,
        closeTo(3.5, 1e-4),
      );
    });

    test('a wardrobe is as tall as the engine says', () {
      final w = boundsOf(model(bedroom()), 'Wardrobe');
      expect(w.y0, closeTo(0, 1e-3));
      expect(w.y1, closeTo(2.1, .15));
    });

    test('pieces stand where the plan puts them', () {
      final g = model(bedroom());
      // the bed: x 0.1 to 2.1 m, 0.7 to 2.1 m north of the south wall
      final bed = boundsOf(g, 'Double bed');
      expect(bed.x0, closeTo(0.1, .2));
      expect(bed.x1, closeTo(2.1, .2));
      expect(bed.z0, closeTo(-2.1, .2), reason: '2.1 m north is z = -2.1');
      expect(bed.z1, closeTo(-0.7, .2));
      // the wardrobe is in the north east corner
      final wd = boundsOf(g, 'Wardrobe');
      expect(wd.x0, greaterThan(2.8));
      expect(wd.z0, closeTo(-3.0, .2));
    });

    test('everything stands on the floor and inside the walls', () {
      final g = model(bedroom());
      for (final name in ['Double bed', 'Wardrobe', 'Bedside table']) {
        final b = boundsOf(g, name);
        expect(b.y0, greaterThanOrEqualTo(-1e-3), reason: name);
        expect(b.x0, greaterThanOrEqualTo(-1e-3), reason: name);
        expect(b.x1, lessThanOrEqualTo(4.2 + 1e-3), reason: name);
        expect(b.z0, greaterThanOrEqualTo(-3.1 - 1e-3), reason: name);
        expect(b.z1, lessThanOrEqualTo(1e-3), reason: name);
      }
    });
  });

  group('walls with openings', () {
    late Glb g;
    late List<Box> walls;
    setUp(() {
      g = model(bedroom());
      walls = boxesOf(g, 'Walls');
    });

    test('a window leaves a hole in the wall, from its sill to its top', () {
      // north wall, 1.5 to 2.9 m along, sill 0.9 m, 1.2 m tall; the wall is
      // at y 3.1 to 3.2 m north, which is z = -3.2 to -3.1
      expect(
        anyInside(walls, 2.2, 1.5, -3.15),
        isFalse,
        reason: 'in the window',
      );
      expect(
        anyInside(walls, 2.2, 0.5, -3.15),
        isTrue,
        reason: 'under the sill',
      );
      expect(
        anyInside(walls, 2.2, 2.4, -3.15),
        isTrue,
        reason: 'over the window',
      );
      expect(
        anyInside(walls, 1.0, 1.5, -3.15),
        isTrue,
        reason: 'beside the window',
      );
      expect(
        anyInside(walls, 3.5, 1.5, -3.15),
        isTrue,
        reason: 'beside it, the other side',
      );
    });

    test('a window on the east wall runs south to north', () {
      // east wall at x 4.2 to 4.3; 0.9 to 2.1 m north of the south wall
      expect(
        anyInside(walls, 4.25, 1.5, -1.5),
        isFalse,
        reason: 'in the window',
      );
      expect(
        anyInside(walls, 4.25, 1.5, -0.4),
        isTrue,
        reason: 'south of the window',
      );
      expect(
        anyInside(walls, 4.25, 1.5, -2.6),
        isTrue,
        reason: 'north of the window',
      );
    });

    test('a door is open to the floor, with wall over it', () {
      // south wall at y -0.1 to 0 (z 0 to 0.1); door 0.6 to 1.5 m along, 2.1 m tall
      expect(
        anyInside(walls, 1.0, 1.0, 0.05),
        isFalse,
        reason: 'in the doorway',
      );
      expect(
        anyInside(walls, 1.0, 2.4, 0.05),
        isTrue,
        reason: 'above the door',
      );
      expect(
        anyInside(walls, 2.5, 1.0, 0.05),
        isTrue,
        reason: 'beside the door',
      );
    });

    test('the windows are glass and the door is a leaf in its opening', () {
      final glass = boxesOf(g, 'Windows');
      expect(glass.length, 2);
      expect(anyInside(glass, 2.2, 1.5, -3.15), isTrue);
      final leaf = boxesOf(g, 'Doors');
      expect(leaf.length, 1);
      expect(anyInside(leaf, 1.0, 1.0, 0.05), isTrue);

      final byName = {for (final m in g.list('materials')) m['name']: m};
      expect(
        (byName['Glass']!['pbrMetallicRoughness'] as Map)['baseColorFactor'][3],
        lessThan(1),
      );
      expect(byName['Glass']!['alphaMode'], 'BLEND');
      expect(byName.containsKey('Door'), isTrue);
    });

    test('the corners are filled, so there is no gap round the room', () {
      for (final (x, z) in [
        (-0.05, -3.15),
        (4.25, -3.15),
        (-0.05, 0.05),
        (4.25, 0.05),
      ]) {
        expect(anyInside(walls, x, 1.5, z), isTrue, reason: 'corner at $x, $z');
      }
    });

    test('the room inside is clear', () {
      expect(anyInside(walls, 2.1, 1.0, -1.5), isFalse);
      expect(anyInside(walls, 0.2, 1.0, -0.2), isFalse);
    });
  });

  group('an L-shaped room', () {
    late Glb g;
    setUp(() => g = model(lBathroom()));

    test('has a floor of just the room, not the corner cut away', () {
      final blocks = boxesOf(g, 'Floor');
      final area = blocks.fold<double>(
        0,
        (sum, b) => sum + (b.x1 - b.x0) * (b.z1 - b.z0),
      );
      expect(area, closeTo(3.0 * 2.4 - 1.2 * 1.0, 1e-4));
      expect(
        anyInside(blocks, 0.9, -0.02, -1.0),
        isTrue,
        reason: 'in the room',
      );
      expect(
        anyInside(blocks, 2.4, -0.02, -1.9),
        isFalse,
        reason: 'in the cut-away corner',
      );
    });

    test('has walls round the notch too', () {
      final walls = boxesOf(g, 'Walls');
      // the notch's two inside walls face into the cut-away corner
      expect(
        anyInside(walls, 1.85, 1.0, -1.9),
        isTrue,
        reason: 'wall at x 1.8 m',
      );
      expect(
        anyInside(walls, 2.4, 1.0, -1.45),
        isTrue,
        reason: 'wall at y 1.4 m',
      );
      expect(
        anyInside(walls, 2.4, 1.0, -1.9),
        isFalse,
        reason: 'the corner itself is open',
      );
    });

    test('keeps its door and window in the right places', () {
      final walls = boxesOf(g, 'Walls');
      // door on the south wall, 0.3 to 1.1 m along
      expect(anyInside(walls, 0.7, 1.0, 0.05), isFalse);
      expect(anyInside(walls, 2.0, 1.0, 0.05), isTrue);
      // window on the west wall, 0.8 to 1.4 m north, sill 1.2 m, 0.7 m tall
      expect(anyInside(walls, -0.05, 1.5, -1.1), isFalse);
      expect(anyInside(walls, -0.05, 0.5, -1.1), isTrue);
      expect(anyInside(walls, -0.05, 1.5, -2.0), isTrue);
    });

    test('has a tiled floor, as a bathroom does', () {
      final names = [for (final m in g.list('materials')) m['name']];
      expect(names, contains('Tile'));
      expect(names, isNot(contains('Wood floor')));
    });

    test('and a bedroom has a wooden one', () {
      final names = [
        for (final m in model(bedroom()).list('materials')) m['name'],
      ];
      expect(names, contains('Wood floor'));
    });
  });

  group('a well-formed file', () {
    for (final (label, layout) in [
      ('bedroom', bedroom()),
      ('bathroom', lBathroom()),
    ]) {
      test('the $label model passes the glTF rules', () {
        final g = model(layout);
        expect(g.magic, 0x46546C67);
        expect(g.length, g.total);
        expect(g.jsonLength % 4, 0);
        expect(g.binLength % 4, 0);
        var triangles = 0;
        for (final node in names(g).toSet()) {
          for (final prim in g.primitives(node)) {
            final vertices = prim.p.length ~/ 3;
            expect(prim.n.length, prim.p.length, reason: node);
            expect(prim.i.length % 3, 0, reason: node);
            expect(
              prim.i.every((i) => i >= 0 && i < vertices),
              isTrue,
              reason: '$node indices in range',
            );
            for (var v = 0; v < prim.n.length; v += 3) {
              final len = math.sqrt(
                math.pow(prim.n[v], 2) +
                    math.pow(prim.n[v + 1], 2) +
                    math.pow(prim.n[v + 2], 2),
              );
              expect(len, closeTo(1, 1e-4), reason: '$node normals');
            }
            final material = prim.prim['material'] as int;
            expect(material, lessThan(g.list('materials').length));
            triangles += prim.i.length ~/ 3;
          }
        }
        expect(triangles, greaterThan(100));
      });
    }

    test('is the same bytes every time for the same room', () {
      expect(roomToGlb(bedroom()), roomToGlb(bedroom()));
    });

    test('is a sensible size, and quick to make', () {
      final watch = Stopwatch()..start();
      final bytes = roomToGlb(bedroom());
      expect(bytes.length, lessThan(500 * 1024));
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('a layout with no room size', () {
    test('cannot be exported, and says so', () {
      final empty = AnalysisLayout.fromJson({
        'layout': {'type': 't', 'title': 'T', 'score': 1},
        'room': {'width': 0, 'length': 0},
      });
      expect(canExportModel(empty), isFalse);
      expect(() => roomToGlb(empty), throwsArgumentError);
      expect(canExportModel(bedroom()), isTrue);
    });

    test('a room with no furniture is still a model of its walls', () {
      final bare = AnalysisLayout.fromJson({
        'layout': {'type': 't', 'title': 'T', 'score': 1},
        'room': {'width': 3000, 'length': 3000, 'height': 2500},
        'furniture': <Object>[],
      });
      expect(names(model(bare)), ['Floor', 'Walls']);
    });
  });
}
