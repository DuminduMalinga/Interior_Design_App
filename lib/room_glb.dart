part of 'main.dart';

/// Whether a layout has what a 3D model needs: a room with a size.
bool canExportModel(AnalysisLayout a) => a.roomWidth > 0 && a.roomLength > 0;

/// The room in the 3D view as a `.glb` model, at real size in metres: the
/// floor, the walls with their doors and windows, and every piece of
/// furniture, each a named object. It is built from the same solids the
/// viewer draws, so the file shows what the screen shows.
///
/// Open it in any 3D tool or AR viewer. Room coordinates are x to the east,
/// y to the north, z up; the model is y-up, as glTF is.
Uint8List roomToGlb(AnalysisLayout a, {String? roomName}) {
  if (!canExportModel(a)) {
    throw ArgumentError('The layout has no room size to build a model from.');
  }

  // the furniture builders work in the viewer's units: the room's longer side
  // is 200 of them
  final aspect = a.roomWidth / a.roomLength;
  final roomW = aspect >= 1 ? 200.0 : 200.0 * aspect;
  final roomD = aspect >= 1 ? 200.0 / aspect : 200.0;
  final k = roomW / a.roomWidth; // viewer units per millimetre
  double metres(double units) => units / k / 1000;

  final widthM = a.roomWidth / 1000;
  final lengthM = a.roomLength / 1000;
  final heightM = (a.roomHeight > 0 ? a.roomHeight : 2800) / 1000;

  final glb = GlbWriter(name: roomName ?? a.title);
  GlbMaterial colour(String name, Color c) =>
      GlbMaterial(name, c.r, c.g, c.b, a: c.a);

  final bathroom = _isBathroom(a.furniture);
  final floorColour = colour(
    bathroom ? 'Tile' : 'Wood floor',
    bathroom
        ? const Color(0xFFC9CDD0)
        : Color.lerp(const Color(0xFFF2EFE9), _Finish.oak, .35)!,
  );
  final wallColour = colour('Wall', const Color(0xFFF1EFEA));
  final glassColour = GlbMaterial(
    'Glass',
    .78,
    .88,
    .94,
    a: .35,
    roughness: .1,
  );
  final doorColour = colour('Door', _Finish.walnut);

  _addShell(
    glb,
    a,
    widthM: widthM,
    lengthM: lengthM,
    heightM: heightM,
    floor: floorColour,
    wall: wallColour,
    glass: glassColour,
    door: doorColour,
  );

  // the furniture: each solid goes to the node of the piece it belongs to
  final owners = <int>[];
  final solids = _buildFurniture(
    a.furniture,
    k: k,
    roomD: roomD,
    roomW: a.roomWidth,
    roomL: a.roomLength,
    owners: owners,
  );
  final nodes = <int, GlbNode>{};
  for (final (i, s) in solids.indexed) {
    final piece = a.furniture[owners[i]];
    final node = nodes.putIfAbsent(
      owners[i],
      () => glb.addNode(
        piece.displayName,
        extras: {'id': piece.id, 'type': piece.type},
      ),
    );
    final m = colour(
      '#${(s.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      s.color,
    );
    // the viewer's y runs south to north the other way, so flip it back
    if (s.round) {
      node.addColumn(
        m,
        cx: metres(s.cx),
        cy: metres(roomD - s.cy),
        rx: metres((s.x1 - s.x0) / 2),
        ry: metres((s.y1 - s.y0) / 2),
        z0: metres(s.z0),
        z1: metres(s.z1),
      );
    } else {
      node.addBox(
        m,
        x0: metres(s.x0),
        y0: metres(roomD - s.y1),
        z0: metres(s.z0),
        x1: metres(s.x1),
        y1: metres(roomD - s.y0),
        z1: metres(s.z1),
      );
    }
  }
  return glb.build();
}

/// One stretch of wall on the room's outline.
class _WallRun {
  _WallRun(this.side, this.line, this.from, this.to);

  /// north, south, east or west: the way the wall faces out of the room.
  final String side;

  /// Where the wall stands across its length, mm (y for north/south, x for
  /// east/west).
  final double line;

  /// Where it starts and ends along its length, mm.
  double from, to;
}

/// The floor as blocks of whole cells: the room less its cutouts (an L-shaped
/// room has a corner cut away). Each is `[x0, y0, x1, y1]` in mm.
List<List<double>> _floorBlocks(AnalysisLayout a) {
  final xs = <double>{0, a.roomWidth};
  final ys = <double>{0, a.roomLength};
  for (final c in a.cutouts) {
    if (c.length < 4) continue;
    xs.addAll([c[0], c[2]].map((v) => v.clamp(0, a.roomWidth).toDouble()));
    ys.addAll([c[1], c[3]].map((v) => v.clamp(0, a.roomLength).toDouble()));
  }
  final x = xs.toList()..sort();
  final y = ys.toList()..sort();
  bool cutAway(double px, double py) => a.cutouts.any(
    (c) =>
        c.length >= 4 &&
        px > math.min(c[0], c[2]) &&
        px < math.max(c[0], c[2]) &&
        py > math.min(c[1], c[3]) &&
        py < math.max(c[1], c[3]),
  );
  return [
    for (var i = 0; i + 1 < x.length; i++)
      for (var j = 0; j + 1 < y.length; j++)
        if (!cutAway((x[i] + x[i + 1]) / 2, (y[j] + y[j + 1]) / 2))
          [x[i], y[j], x[i + 1], y[j + 1]],
  ];
}

/// The wall runs round the outline of [blocks], with neighbouring ones that
/// line up joined into one.
List<_WallRun> _wallRuns(List<List<double>> blocks) {
  // the cell next door on each side, found by a point just past the edge
  bool filled(double px, double py) =>
      blocks.any((b) => px > b[0] && px < b[2] && py > b[1] && py < b[3]);
  final runs = <_WallRun>[];
  for (final b in blocks) {
    final mx = (b[0] + b[2]) / 2, my = (b[1] + b[3]) / 2;
    const eps = .5;
    if (!filled(mx, b[3] + eps)) runs.add(_WallRun('north', b[3], b[0], b[2]));
    if (!filled(mx, b[1] - eps)) runs.add(_WallRun('south', b[1], b[0], b[2]));
    if (!filled(b[2] + eps, my)) runs.add(_WallRun('east', b[2], b[1], b[3]));
    if (!filled(b[0] - eps, my)) runs.add(_WallRun('west', b[0], b[1], b[3]));
  }

  // join runs that touch on the same line
  runs.sort((p, q) {
    final bySide = p.side.compareTo(q.side);
    if (bySide != 0) return bySide;
    final byLine = p.line.compareTo(q.line);
    return byLine != 0 ? byLine : p.from.compareTo(q.from);
  });
  final joined = <_WallRun>[];
  for (final r in runs) {
    if (joined.isNotEmpty) {
      final last = joined.last;
      if (last.side == r.side &&
          last.line == r.line &&
          (r.from - last.to).abs() < .5) {
        last.to = r.to;
        continue;
      }
    }
    joined.add(_WallRun(r.side, r.line, r.from, r.to));
  }
  return joined;
}

/// Adds the floor, walls, windows and doors.
void _addShell(
  GlbWriter glb,
  AnalysisLayout a, {
  required double widthM,
  required double lengthM,
  required double heightM,
  required GlbMaterial floor,
  required GlbMaterial wall,
  required GlbMaterial glass,
  required GlbMaterial door,
}) {
  double m(double mm) => mm / 1000;
  const thick = .1; // walls stand outside the room, so its size stays true
  const slab = .05;

  final floorNode = glb.addNode('Floor');
  final blocks = _floorBlocks(a);
  for (final b in blocks) {
    floorNode.addBox(
      floor,
      x0: m(b[0]),
      y0: m(b[1]),
      z0: -slab,
      x1: m(b[2]),
      y1: m(b[3]),
      z1: 0,
    );
  }

  final wallNode = glb.addNode('Walls');
  final windowNode = glb.addNode('Windows');
  final doorNode = glb.addNode('Doors');

  void wallBox(
    String side,
    double from,
    double to,
    double line,
    double z0,
    double z1,
    GlbNode node,
    GlbMaterial material, {
    double offset = 0,
    double depth = thick,
  }) {
    if (to - from <= 0 || z1 <= z0) return;
    // `offset` and `depth` place the box across the wall, from its inner face
    final inner = switch (side) {
      'north' || 'east' => line + offset,
      _ => line - offset - depth,
    };
    if (side == 'north' || side == 'south') {
      node.addBox(
        material,
        x0: from,
        y0: inner,
        z0: z0,
        x1: to,
        y1: inner + depth,
        z1: z1,
      );
    } else {
      node.addBox(
        material,
        x0: inner,
        y0: from,
        z0: z0,
        x1: inner + depth,
        y1: to,
        z1: z1,
      );
    }
  }

  for (final run in _wallRuns(blocks)) {
    final line = m(run.line);
    var from = m(run.from), to = m(run.to);
    // corners of the room's outline are filled by the north and south walls
    if (run.side == 'north' || run.side == 'south') {
      if (run.from == 0) from -= thick;
      if ((run.to - a.roomWidth).abs() < .5) to += thick;
    }

    // the openings that sit in this stretch of wall
    final expected = switch (run.side) {
      'north' => a.roomLength,
      'east' => a.roomWidth,
      _ => 0.0,
    };
    final cuts = <(double, double, AnalysisOpening)>[];
    for (final o in a.openings) {
      if (o.wall != run.side) continue;
      final onLine = run.side == 'north' || run.side == 'east'
          ? expected - o.inset
          : o.inset;
      if ((run.line - onLine).abs() > 1) continue;
      final s = math.max(m(o.position), from);
      final e = math.min(m(o.position + o.width), to);
      if (e > s) cuts.add((s, e, o));
    }
    cuts.sort((p, q) => p.$1.compareTo(q.$1));

    var cursor = from;
    for (final (s, e, o) in cuts) {
      wallBox(
        run.side,
        cursor,
        math.max(cursor, s),
        line,
        0,
        heightM,
        wallNode,
        wall,
      );
      final sill = o.isDoor ? 0.0 : m(o.sillHeight ?? 900);
      final top = o.isDoor ? 2.1 : sill + m(o.height ?? 1200);
      final lo = math.max(cursor, s);
      if (sill > 0) wallBox(run.side, lo, e, line, 0, sill, wallNode, wall);
      wallBox(
        run.side,
        lo,
        e,
        line,
        math.min(top, heightM),
        heightM,
        wallNode,
        wall,
      );
      // the glass or the door leaf, in the middle of the wall's thickness
      if (o.isDoor) {
        wallBox(
          run.side,
          lo,
          e,
          line,
          0,
          top,
          doorNode,
          door,
          offset: thick * .4,
          depth: .04,
        );
      } else {
        wallBox(
          run.side,
          lo,
          e,
          line,
          sill,
          top,
          windowNode,
          glass,
          offset: thick * .45,
          depth: .02,
        );
      }
      cursor = math.max(cursor, e);
    }
    wallBox(run.side, cursor, to, line, 0, heightM, wallNode, wall);
  }
}
