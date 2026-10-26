import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// A writer for binary glTF (`.glb`) models, the format 3D tools, AR viewers
/// and the web's own exporter use. It makes plain coloured solids (boxes and
/// round columns), which is all the room's furniture is built from.
///
/// Shapes are given in room terms: metres, x to the east, y to the north and
/// z up. glTF is y-up, so they are turned a quarter on the way in; that is a
/// rotation, not a mirror, so nothing is flipped.

/// A flat colour. Colours are given as they look on screen (sRGB) and stored
/// the way glTF wants them (linear).
class GlbMaterial {
  /// [r], [g], [b] and [a] are 0 to 1.
  GlbMaterial(
    this.name,
    double r,
    double g,
    double b, {
    this.a = 1,
    this.roughness = .8,
    this.metallic = 0,
  }) : r = _linear(r),
       g = _linear(g),
       b = _linear(b);

  final String name;
  final double r, g, b, a, roughness, metallic;

  /// See-through colours (glass) blend with what is behind them.
  bool get blends => a < 1;

  String get key => '$r|$g|$b|$a|$roughness|$metallic';

  static double _linear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// The triangles of one colour within one node.
class _Primitive {
  _Primitive(this.material);

  final int material;
  final positions = <double>[];
  final normals = <double>[];
  final indices = <int>[];

  int get vertexCount => positions.length ~/ 3;
}

/// One named object in the model: a piece of furniture, the floor, a wall.
class GlbNode {
  GlbNode._(this.name, this.extras, this._writer);

  final String name;

  /// Anything worth keeping with the object (an id, a type), shown by tools
  /// that read glTF "extras".
  final Map<String, Object?>? extras;
  final GlbWriter _writer;
  final _primitives = <int, _Primitive>{};

  bool get isEmpty => _primitives.isEmpty;

  _Primitive _of(GlbMaterial m) => _primitives.putIfAbsent(
    _writer._material(m),
    () => _Primitive(_writer._material(m)),
  );

  /// Adds a block spanning the two corners, in room coordinates.
  void addBox(
    GlbMaterial m, {
    required double x0,
    required double y0,
    required double z0,
    required double x1,
    required double y1,
    required double z1,
  }) {
    if (x1 <= x0 || y1 <= y0 || z1 <= z0) return;
    // each face: its outward normal and its corners, counter-clockwise as seen
    // from outside, which is the way glTF says a front face runs
    final faces = <(List<double>, List<List<double>>)>[
      (
        [1, 0, 0],
        [
          [x1, y0, z0],
          [x1, y1, z0],
          [x1, y1, z1],
          [x1, y0, z1],
        ],
      ),
      (
        [-1, 0, 0],
        [
          [x0, y1, z0],
          [x0, y0, z0],
          [x0, y0, z1],
          [x0, y1, z1],
        ],
      ),
      (
        [0, 1, 0],
        [
          [x1, y1, z0],
          [x0, y1, z0],
          [x0, y1, z1],
          [x1, y1, z1],
        ],
      ),
      (
        [0, -1, 0],
        [
          [x0, y0, z0],
          [x1, y0, z0],
          [x1, y0, z1],
          [x0, y0, z1],
        ],
      ),
      (
        [0, 0, 1],
        [
          [x0, y0, z1],
          [x1, y0, z1],
          [x1, y1, z1],
          [x0, y1, z1],
        ],
      ),
      (
        [0, 0, -1],
        [
          [x0, y1, z0],
          [x1, y1, z0],
          [x1, y0, z0],
          [x0, y0, z0],
        ],
      ),
    ];
    final p = _of(m);
    for (final (n, corners) in faces) {
      final base = p.vertexCount;
      for (final c in corners) {
        _put(p, c[0], c[1], c[2], n[0], n[1], n[2]);
      }
      p.indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
    }
  }

  /// Adds an upright round column (an ellipse if [rx] and [ry] differ)
  /// centred on ([cx], [cy]).
  void addColumn(
    GlbMaterial m, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required double z0,
    required double z1,
    int sides = 24,
  }) {
    if (rx <= 0 || ry <= 0 || z1 <= z0) return;
    final p = _of(m);
    double px(int i) => cx + rx * math.cos(2 * math.pi * i / sides);
    double py(int i) => cy + ry * math.sin(2 * math.pi * i / sides);

    // the side, with normals that follow the curve
    final ring = p.vertexCount;
    for (var i = 0; i <= sides; i++) {
      final t = 2 * math.pi * i / sides;
      var nx = math.cos(t) / rx, ny = math.sin(t) / ry;
      final len = math.sqrt(nx * nx + ny * ny);
      nx /= len;
      ny /= len;
      _put(p, px(i), py(i), z0, nx, ny, 0);
      _put(p, px(i), py(i), z1, nx, ny, 0);
    }
    for (var i = 0; i < sides; i++) {
      final a = ring + 2 * i; // bottom i, top i, bottom i+1, top i+1
      p.indices.addAll([a, a + 2, a + 3, a, a + 3, a + 1]);
    }

    // the top and the bottom
    for (final top in [true, false]) {
      final z = top ? z1 : z0;
      final nz = top ? 1.0 : -1.0;
      final centre = p.vertexCount;
      _put(p, cx, cy, z, 0, 0, nz);
      final first = p.vertexCount;
      for (var i = 0; i < sides; i++) {
        _put(p, px(i), py(i), z, 0, 0, nz);
      }
      for (var i = 0; i < sides; i++) {
        final a = first + i, b = first + (i + 1) % sides;
        p.indices.addAll(top ? [centre, a, b] : [centre, b, a]);
      }
    }
  }

  /// Stores a vertex, turning room coordinates (z up) into glTF's (y up).
  static void _put(
    _Primitive p,
    double x,
    double y,
    double z,
    double nx,
    double ny,
    double nz,
  ) {
    p.positions.addAll([x, z, -y]);
    p.normals.addAll([nx, nz, -ny]);
  }
}

/// Builds a model out of named [GlbNode]s and writes it as a `.glb`.
class GlbWriter {
  GlbWriter({this.name = 'Model', this.generator = 'LiviSpace'});

  /// The name of the scene, as 3D tools list it.
  final String name;
  final String generator;

  final _materials = <GlbMaterial>[];
  final _materialIndex = <String, int>{};
  final _nodes = <GlbNode>[];

  int _material(GlbMaterial m) => _materialIndex.putIfAbsent(m.key, () {
    _materials.add(m);
    return _materials.length - 1;
  });

  /// A new named object to add shapes to. One with no shapes is left out.
  GlbNode addNode(String name, {Map<String, Object?>? extras}) {
    final node = GlbNode._(name, extras, this);
    _nodes.add(node);
    return node;
  }

  /// The model as a `.glb` file's bytes.
  Uint8List build() {
    final bin = BytesBuilder();
    final bufferViews = <Map<String, Object?>>[];
    final accessors = <Map<String, Object?>>[];
    final meshes = <Map<String, Object?>>[];
    final nodes = <Map<String, Object?>>[];

    void pad() {
      while (bin.length % 4 != 0) {
        bin.addByte(0);
      }
    }

    int view(Uint8List bytes, int target) {
      pad();
      bufferViews.add({
        'buffer': 0,
        'byteOffset': bin.length,
        'byteLength': bytes.length,
        'target': target,
      });
      bin.add(bytes);
      return bufferViews.length - 1;
    }

    for (final node in _nodes) {
      if (node.isEmpty) continue;
      final primitives = <Map<String, Object?>>[];
      for (final p in node._primitives.values) {
        final count = p.vertexCount;
        if (count == 0 || p.indices.isEmpty) continue;

        final lows = [double.infinity, double.infinity, double.infinity];
        final highs = [-double.infinity, -double.infinity, -double.infinity];
        for (var i = 0; i < p.positions.length; i++) {
          final axis = i % 3;
          lows[axis] = math.min(lows[axis], p.positions[i]);
          highs[axis] = math.max(highs[axis], p.positions[i]);
        }

        accessors.add({
          'bufferView': view(
            Float32List.fromList(p.positions).buffer.asUint8List(),
            34962,
          ),
          'componentType': 5126,
          'count': count,
          'type': 'VEC3',
          'min': lows,
          'max': highs,
        });
        final positionAccessor = accessors.length - 1;
        accessors.add({
          'bufferView': view(
            Float32List.fromList(p.normals).buffer.asUint8List(),
            34962,
          ),
          'componentType': 5126,
          'count': count,
          'type': 'VEC3',
        });
        final normalAccessor = accessors.length - 1;
        final wide = count > 65535;
        accessors.add({
          'bufferView': view(
            wide
                ? Uint32List.fromList(p.indices).buffer.asUint8List()
                : Uint16List.fromList(p.indices).buffer.asUint8List(),
            34963,
          ),
          'componentType': wide ? 5125 : 5123,
          'count': p.indices.length,
          'type': 'SCALAR',
        });
        primitives.add({
          'attributes': {
            'POSITION': positionAccessor,
            'NORMAL': normalAccessor,
          },
          'indices': accessors.length - 1,
          'material': p.material,
          'mode': 4,
        });
      }
      if (primitives.isEmpty) continue;
      meshes.add({'name': node.name, 'primitives': primitives});
      nodes.add({
        'name': node.name,
        'mesh': meshes.length - 1,
        if (node.extras != null) 'extras': node.extras,
      });
    }
    pad();

    final json = <String, Object?>{
      'asset': {'version': '2.0', 'generator': generator},
      'scene': 0,
      'scenes': [
        {
          'name': name,
          'nodes': [for (var i = 0; i < nodes.length; i++) i],
        },
      ],
      'nodes': nodes,
      'meshes': meshes,
      'materials': [
        for (final m in _materials)
          {
            'name': m.name,
            'pbrMetallicRoughness': {
              'baseColorFactor': [m.r, m.g, m.b, m.a],
              'metallicFactor': m.metallic,
              'roughnessFactor': m.roughness,
            },
            if (m.blends) 'alphaMode': 'BLEND',
          },
      ],
      'accessors': accessors,
      'bufferViews': bufferViews,
      'buffers': [
        {'byteLength': bin.length},
      ],
    };

    // the JSON chunk is padded with spaces and the binary one with zeros, so
    // each ends on a four-byte boundary
    final jsonBytes = utf8.encode(jsonEncode(json));
    final jsonPadded = (jsonBytes.length + 3) & ~3;
    final binBytes = bin.toBytes();
    final total = 12 + 8 + jsonPadded + 8 + binBytes.length;

    final out = BytesBuilder();
    final header = ByteData(20)
      ..setUint32(0, 0x46546C67, Endian.little) // "glTF"
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, total, Endian.little)
      ..setUint32(12, jsonPadded, Endian.little)
      ..setUint32(16, 0x4E4F534A, Endian.little); // "JSON"
    out.add(header.buffer.asUint8List());
    out.add(jsonBytes);
    for (var i = jsonBytes.length; i < jsonPadded; i++) {
      out.addByte(0x20);
    }
    final binHeader = ByteData(8)
      ..setUint32(0, binBytes.length, Endian.little)
      ..setUint32(4, 0x004E4942, Endian.little); // "BIN\0"
    out.add(binHeader.buffer.asUint8List());
    out.add(binBytes);
    return out.toBytes();
  }
}
