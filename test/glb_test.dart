import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/glb.dart';

import 'glb_reader.dart';

/// What a model of a few shapes looks like once written.
void main() {
  final wood = GlbMaterial('Wood', .8, .6, .4);
  final glass = GlbMaterial('Glass', .8, .9, 1, a: .3);

  Glb oneBox({
    double x0 = 0,
    double y0 = 0,
    double z0 = 0,
    double x1 = 2,
    double y1 = 3,
    double z1 = 1,
  }) {
    final w = GlbWriter(name: 'Test');
    w
        .addNode('Box')
        .addBox(wood, x0: x0, y0: y0, z0: z0, x1: x1, y1: y1, z1: z1);
    return Glb(w.build());
  }

  group('the file', () {
    test('has a glTF header and two chunks that fit the file exactly', () {
      final bytes =
          (GlbWriter()
                ..addNode(
                  'a',
                ).addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1))
              .build();
      final g = Glb(bytes);
      expect(g.magic, 0x46546C67, reason: '"glTF"');
      expect(g.version, 2);
      expect(g.length, bytes.length, reason: 'the header says how long it is');
      expect(g.jsonType, 0x4E4F534A, reason: '"JSON"');
      expect(g.binType, 0x004E4942, reason: '"BIN"');
      expect(g.total, 12 + 8 + g.jsonLength + 8 + g.binLength);
    });

    test('keeps both chunks on four-byte boundaries', () {
      for (final name in [
        'a',
        'ab',
        'abc',
        'abcd',
        'a long name for the node',
      ]) {
        final w = GlbWriter(name: name);
        w.addNode(name).addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
        final g = Glb(w.build());
        expect(g.jsonLength % 4, 0, reason: name);
        expect(g.binLength % 4, 0, reason: name);
        expect(g.total % 4, 0, reason: name);
      }
    });

    test('names the scene and the program that wrote it', () {
      final g = oneBox();
      expect((g.json['asset'] as Map)['version'], '2.0');
      expect((g.json['asset'] as Map)['generator'], 'LiviSpace');
      expect(g.list('scenes').single['name'], 'Test');
    });

    test('is the same bytes every time for the same model', () {
      expect(oneBox().total, oneBox().total);
      final a =
          (GlbWriter()
                ..addNode(
                  'n',
                ).addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1))
              .build();
      final b =
          (GlbWriter()
                ..addNode(
                  'n',
                ).addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1))
              .build();
      expect(a, b);
    });
  });

  group('buffers', () {
    test('every view lies inside the buffer, aligned to four bytes', () {
      final w = GlbWriter();
      final n = w.addNode('mix');
      n.addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      n.addColumn(glass, cx: 2, cy: 2, rx: .3, ry: .2, z0: 0, z1: 1);
      final g = Glb(w.build());
      final size = g.list('buffers').single['byteLength'] as int;
      expect(size, g.binLength);
      for (final v in g.list('bufferViews')) {
        expect(v['byteOffset'] as int, isNonNegative);
        expect((v['byteOffset'] as int) % 4, 0);
        expect(
          (v['byteOffset'] as int) + (v['byteLength'] as int),
          lessThanOrEqualTo(size),
        );
      }
    });

    test('each accessor fills its view and its min and max are true', () {
      final g = oneBox(x0: 1, y0: 2, z0: 3, x1: 4, y1: 6, z1: 8);
      for (final (i, a) in g.list('accessors').indexed) {
        final view = g.list('bufferViews')[a['bufferView'] as int];
        final bytes = {5126: 4, 5123: 2, 5125: 4}[a['componentType']]!;
        final comps = {'SCALAR': 1, 'VEC3': 3}[a['type']]!;
        expect(view['byteLength'], (a['count'] as int) * comps * bytes);
        if (a['type'] == 'VEC3' && a.containsKey('min')) {
          final p = g.read(i);
          for (var axis = 0; axis < 3; axis++) {
            final values = [for (var k = axis; k < p.length; k += 3) p[k]];
            expect(
              (a['min'] as List)[axis],
              closeTo(values.reduce(math.min).toDouble(), 1e-5),
            );
            expect(
              (a['max'] as List)[axis],
              closeTo(values.reduce(math.max).toDouble(), 1e-5),
            );
          }
        }
      }
    });

    test('indices are 16-bit, and 32-bit once there are too many vertices', () {
      final small = oneBox();
      expect(small.list('accessors').last['componentType'], 5123);

      final w = GlbWriter();
      final big = w.addNode('many');
      for (var i = 0; i < 3000; i++) {
        big.addBox(
          wood,
          x0: i.toDouble(),
          y0: 0,
          z0: 0,
          x1: i + .5,
          y1: 1,
          z1: 1,
        );
      }
      final g = Glb(w.build());
      final prim = g.primitives('many').single;
      expect(prim.prim['indices'], isNotNull);
      expect(g.accessor(prim.prim['indices'] as int)['componentType'], 5125);
      expect(prim.p.length ~/ 3, 3000 * 24);
      expect(prim.i.reduce(math.max), lessThan(3000 * 24));
    });
  });

  group('a box', () {
    test('has six faces: 24 vertices and 12 triangles', () {
      final prim = oneBox().primitives('Box').single;
      expect(prim.p.length ~/ 3, 24);
      expect(prim.n.length ~/ 3, 24);
      expect(prim.i.length ~/ 3, 12);
    });

    test('lands in glTF space: x east, up is y, north is -z', () {
      // room x 1..4, y (north) 2..6, z (up) 3..8
      final a = oneBox(x0: 1, y0: 2, z0: 3, x1: 4, y1: 6, z1: 8).accessor(0);
      expect(a['min'], [1.0, 3.0, -6.0]);
      expect(a['max'], [4.0, 8.0, -2.0]);
    });

    test(
      'has unit normals, and every triangle winds the way its normal points',
      () {
        final prim = oneBox(
          x0: -1,
          y0: 0,
          z0: 0,
          x1: 2,
          y1: 1,
          z1: 4,
        ).primitives('Box').single;
        for (var v = 0; v < prim.n.length; v += 3) {
          final len = math.sqrt(
            prim.n[v] * prim.n[v] +
                prim.n[v + 1] * prim.n[v + 1] +
                prim.n[v + 2] * prim.n[v + 2],
          );
          expect(len, closeTo(1, 1e-6));
        }
        for (var t = 0; t < prim.i.length; t += 3) {
          List<double> at(int k) {
            final i = prim.i[t + k].toInt() * 3;
            return [
              prim.p[i].toDouble(),
              prim.p[i + 1].toDouble(),
              prim.p[i + 2].toDouble(),
            ];
          }

          final a = at(0), b = at(1), c = at(2);
          final face = cross(
            [b[0] - a[0], b[1] - a[1], b[2] - a[2]],
            [c[0] - a[0], c[1] - a[1], c[2] - a[2]],
          );
          final i0 = prim.i[t].toInt() * 3;
          final dot =
              face[0] * prim.n[i0] +
              face[1] * prim.n[i0 + 1] +
              face[2] * prim.n[i0 + 2];
          expect(
            dot,
            greaterThan(0),
            reason: 'triangle ${t ~/ 3} faces inward',
          );
        }
      },
    );

    test('a shape with no size is left out', () {
      final w = GlbWriter();
      final n = w.addNode('flat');
      n.addBox(wood, x0: 0, y0: 0, z0: 0, x1: 0, y1: 1, z1: 1);
      n.addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: -1);
      expect(n.isEmpty, isTrue);
    });
  });

  group('a round column', () {
    GlbNode column(GlbWriter w, {int sides = 24}) {
      final n = w.addNode('Column');
      n.addColumn(
        wood,
        cx: 1,
        cy: 2,
        rx: .5,
        ry: .25,
        z0: 0,
        z1: 3,
        sides: sides,
      );
      return n;
    }

    test('spans its radii and height, centred where it is put', () {
      final w = GlbWriter();
      column(w);
      final a = Glb(w.build()).accessor(0);
      expect((a['min'] as List)[0], closeTo(.5, 1e-5)); // x: 1 - .5
      expect((a['max'] as List)[0], closeTo(1.5, 1e-5));
      expect((a['min'] as List)[1], closeTo(0, 1e-5)); // up
      expect((a['max'] as List)[1], closeTo(3, 1e-5));
      expect((a['min'] as List)[2], closeTo(-2.25, 1e-5)); // -(y + ry)
      expect((a['max'] as List)[2], closeTo(-1.75, 1e-5));
    });

    test('has the vertices and triangles of its sides and two caps', () {
      const sides = 12;
      final w = GlbWriter();
      column(w, sides: sides);
      final prim = Glb(w.build()).primitives('Column').single;
      expect(prim.p.length ~/ 3, (sides + 1) * 2 + 2 * (sides + 1));
      expect(prim.i.length ~/ 3, sides * 2 + 2 * sides);
    });

    test('winds outward on the sides and up and down on the caps', () {
      final w = GlbWriter();
      column(w);
      final prim = Glb(w.build()).primitives('Column').single;
      var checked = 0;
      for (var t = 0; t < prim.i.length; t += 3) {
        List<double> at(int k) {
          final i = prim.i[t + k].toInt() * 3;
          return [
            prim.p[i].toDouble(),
            prim.p[i + 1].toDouble(),
            prim.p[i + 2].toDouble(),
          ];
        }

        final a = at(0), b = at(1), c = at(2);
        final face = cross(
          [b[0] - a[0], b[1] - a[1], b[2] - a[2]],
          [c[0] - a[0], c[1] - a[1], c[2] - a[2]],
        );
        final i0 = prim.i[t].toInt() * 3;
        final dot =
            face[0] * prim.n[i0] +
            face[1] * prim.n[i0 + 1] +
            face[2] * prim.n[i0 + 2];
        expect(dot, greaterThan(0), reason: 'triangle ${t ~/ 3}');
        checked++;
      }
      expect(checked, greaterThan(40));
    });

    test('a flat or hollow one is left out', () {
      final w = GlbWriter();
      final n = w.addNode('x');
      n.addColumn(wood, cx: 0, cy: 0, rx: 0, ry: 1, z0: 0, z1: 1);
      n.addColumn(wood, cx: 0, cy: 0, rx: 1, ry: 1, z0: 1, z1: 1);
      expect(n.isEmpty, isTrue);
    });
  });

  group('materials', () {
    test('are stored in linear colour, as glTF wants', () {
      final w = GlbWriter();
      w
          .addNode('n')
          .addBox(
            GlbMaterial('Grey', .5, .5, .5),
            x0: 0,
            y0: 0,
            z0: 0,
            x1: 1,
            y1: 1,
            z1: 1,
          );
      final factor =
          ((Glb(w.build()).list('materials').single['pbrMetallicRoughness']
                  as Map)['baseColorFactor']
              as List);
      expect(
        factor[0],
        closeTo(0.2140, 1e-3),
        reason: 'sRGB 0.5 is about 0.214 linear',
      );
      expect(factor[3], 1);
    });

    test('the same colour used twice is one material', () {
      final w = GlbWriter();
      final n = w.addNode('n');
      for (var i = 0; i < 5; i++) {
        n.addBox(
          GlbMaterial('Wood', .8, .6, .4),
          x0: i.toDouble(),
          y0: 0,
          z0: 0,
          x1: i + 1.0,
          y1: 1,
          z1: 1,
        );
      }
      w
          .addNode('m')
          .addBox(
            GlbMaterial('Other name', .8, .6, .4),
            x0: 0,
            y0: 0,
            z0: 5,
            x1: 1,
            y1: 1,
            z1: 6,
          );
      final g = Glb(w.build());
      expect(g.list('materials'), hasLength(1));
      expect(
        g.primitives('n'),
        hasLength(1),
        reason: 'one primitive per colour',
      );
    });

    test('different colours are different primitives of the same node', () {
      final w = GlbWriter();
      final n = w.addNode('n');
      n.addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      n.addBox(glass, x0: 2, y0: 0, z0: 0, x1: 3, y1: 1, z1: 1);
      final g = Glb(w.build());
      expect(g.list('materials'), hasLength(2));
      expect(g.primitives('n'), hasLength(2));
    });

    test('only see-through ones blend', () {
      final w = GlbWriter();
      final n = w.addNode('n');
      n.addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      n.addBox(glass, x0: 2, y0: 0, z0: 0, x1: 3, y1: 1, z1: 1);
      final byName = {
        for (final m in Glb(w.build()).list('materials')) m['name']: m,
      };
      expect(byName['Wood']!.containsKey('alphaMode'), isFalse);
      expect(byName['Glass']!['alphaMode'], 'BLEND');
    });

    test('a material nobody uses is not written', () {
      final w = GlbWriter();
      w
          .addNode('n')
          .addBox(wood, x0: 0, y0: 0, z0: 0, x1: 0, y1: 1, z1: 1); // no size
      w.addNode('real').addBox(glass, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      expect(Glb(w.build()).list('materials'), hasLength(1));
    });
  });

  group('nodes', () {
    test('are named, and keep what was attached to them', () {
      final w = GlbWriter();
      w
          .addNode('Sofa', extras: {'id': 's-1', 'type': 'sofa'})
          .addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      final node = Glb(w.build()).list('nodes').single;
      expect(node['name'], 'Sofa');
      expect(node['extras'], {'id': 's-1', 'type': 'sofa'});
    });

    test('every node is in the scene, and an empty one is left out', () {
      final w = GlbWriter();
      w.addNode('a').addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      w.addNode('empty');
      w.addNode('b').addBox(wood, x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1);
      final g = Glb(w.build());
      expect([for (final n in g.list('nodes')) n['name']], ['a', 'b']);
      expect(g.list('scenes').single['nodes'], [0, 1]);
    });

    test('a model with nothing in it is still a valid, empty file', () {
      final g = Glb(GlbWriter().build());
      expect(g.magic, 0x46546C67);
      expect(g.list('nodes'), isEmpty);
      expect(g.list('scenes').single['nodes'], isEmpty);
    });
  });
}
