import 'dart:convert';
import 'dart:typed_data';

/// A `.glb` taken apart again, so the tests check the file itself rather than
/// the writer's own idea of it.
class Glb {
  Glb(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    magic = data.getUint32(0, Endian.little);
    version = data.getUint32(4, Endian.little);
    length = data.getUint32(8, Endian.little);
    jsonLength = data.getUint32(12, Endian.little);
    jsonType = data.getUint32(16, Endian.little);
    json =
        jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
            as Map<String, dynamic>;
    final binAt = 20 + jsonLength;
    binLength = data.getUint32(binAt, Endian.little);
    binType = data.getUint32(binAt + 4, Endian.little);
    bin = Uint8List.sublistView(bytes, binAt + 8, binAt + 8 + binLength);
    total = bytes.length;
  }

  late final int magic, version, length, jsonLength, jsonType;
  late final int binLength, binType, total;
  late final Map<String, dynamic> json;
  late final Uint8List bin;

  List<Map<String, dynamic>> list(String key) =>
      ((json[key] ?? <Object>[]) as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> accessor(int i) => list('accessors')[i];

  /// The numbers an accessor points at.
  List<num> read(int accessorIndex) {
    final a = accessor(accessorIndex);
    final view = list('bufferViews')[a['bufferView'] as int];
    final offset =
        (view['byteOffset'] as int) + ((a['byteOffset'] ?? 0) as int);
    final components = {'SCALAR': 1, 'VEC3': 3}[a['type']]!;
    final count = (a['count'] as int) * components;
    final data = ByteData.sublistView(bin);
    return switch (a['componentType']) {
      5126 => [
        for (var i = 0; i < count; i++)
          data.getFloat32(offset + i * 4, Endian.little),
      ],
      5123 => [
        for (var i = 0; i < count; i++)
          data.getUint16(offset + i * 2, Endian.little),
      ],
      5125 => [
        for (var i = 0; i < count; i++)
          data.getUint32(offset + i * 4, Endian.little),
      ],
      _ => throw StateError('unexpected component type'),
    };
  }

  /// Each primitive of the node called [name], as positions, normals, indices.
  List<({List<num> p, List<num> n, List<num> i, Map<String, dynamic> prim})>
  primitives(String name) {
    final node = list('nodes').firstWhere((n) => n['name'] == name);
    final mesh = list('meshes')[node['mesh'] as int];
    return [
      for (final prim
          in (mesh['primitives'] as List).cast<Map<String, dynamic>>())
        (
          p: read((prim['attributes'] as Map)['POSITION'] as int),
          n: read((prim['attributes'] as Map)['NORMAL'] as int),
          i: read(prim['indices'] as int),
          prim: prim,
        ),
    ];
  }
}

List<double> cross(List<double> a, List<double> b) => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];
