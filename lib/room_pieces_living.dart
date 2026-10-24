part of 'main.dart';

// Living-room furniture: the seating group, the tables, the TV wall, the
// bookshelf and the rug (the web's `scene3d/living.ts`). The dining table,
// desk and lamp that a living room can also hold are drawn here too.

const _cushionAccents = [_Finish.terracotta, _Finish.sage, _Finish.mustard];

final Map<String, _PieceBuilder> _livingPieces = {
  'sofa': _sofa,
  'loveseat': _sofa,
  'chair': _armchair,
  'reading_chair': _readingChair,
  'coffee_table': _coffeeTable,
  'side_table': _sideTable,
  'tv_console': _tvConsole,
  'tv': _television,
  'bookshelf': _bookshelf,
  'rug': _rug,
  'lamp': _floorLamp,
};

/// A sofa or an armchair: a frame on legs, arms, and a seat and back cushion
/// for each place.
void _upholstered(
  _PieceCtx p, {
  required Color color,
  required double arm,
  required double leg,
  required int pillows,
  bool leather = false,
}) {
  final w = p.w;
  final d = p.d;
  final h = math.max(p.h, .7);
  final cushion = _tone(color, leather ? .06 : .08);
  final back = math.min(.2, d * .24);
  const frame = .17;
  final seatTop = leg + frame + .15;

  p.legs(leg, _Finish.walnut, r: .024, inset: .06);
  p.box(-w / 2, w / 2, -d / 2, d / 2, leg, leg + frame, color);
  final armTop = math.min(seatTop + .14, h - .12);
  for (final side in const [-1.0, 1.0]) {
    final u0 = side < 0 ? -w / 2 : w / 2 - arm;
    p.box(u0, u0 + arm, -d / 2, d / 2, leg, armTop, _tone(color, -.05));
  }
  final inner = w - 2 * arm;
  p.box(
    -inner / 2,
    inner / 2,
    -d / 2,
    -d / 2 + back,
    leg,
    h,
    _tone(color, -.03),
  );

  final places = inner >= 1.55
      ? 3
      : inner >= 1.05
      ? 2
      : 1;
  final cw = inner / places;
  for (var i = 0; i < places; i++) {
    final u0 = -inner / 2 + cw * i + .006;
    final u1 = u0 + cw - .012;
    p.box(u0, u1, -d / 2 + back, d / 2 - .01, seatTop - .16, seatTop, cushion);
    p.box(
      u0,
      u1,
      -d / 2 + back,
      -d / 2 + back + .15,
      seatTop,
      seatTop + math.min(.4, h - seatTop + .02),
      cushion,
    );
  }
  for (var i = 0; i < pillows; i++) {
    final side = places == 1 ? 0.0 : (i == 0 ? -1.0 : 1.0);
    final size = places == 1 ? .34 : .4;
    final u = side * (inner / 2 - .23);
    p.box(
      u - size / 2,
      u + size / 2,
      -d / 2 + back + .02,
      -d / 2 + back + .14,
      seatTop,
      seatTop + size * .95,
      _cushionAccents[(p.index + i) % _cushionAccents.length],
    );
  }
}

void _sofa(_PieceCtx p) =>
    _upholstered(p, color: _Finish.greige, arm: .17, leg: .13, pillows: 2);

void _armchair(_PieceCtx p) =>
    _upholstered(p, color: _Finish.teal, arm: .13, leg: .15, pillows: 1);

void _readingChair(_PieceCtx p) => _upholstered(
  p,
  color: _Finish.caramel,
  arm: .1,
  leg: .19,
  pillows: 0,
  leather: true,
);

/// A corner sofa is built from its rectangles, already in room coordinates.
void _cornerSofa(_PieceCtx p) {
  final item = p.item;
  final cover = _Finish.greige;
  final cushion = _tone(cover, .08);
  const backT = 200.0;
  final h = math.max(item.height, 700.0);
  final bbox = [item.x0, item.y0, item.x1, item.y1];
  bool south(List<double> q) => (q[1] - bbox[1]).abs() < 1;
  bool north(List<double> q) => (q[3] - bbox[3]).abs() < 1;
  bool west(List<double> q) => (q[0] - bbox[0]).abs() < 1;
  bool east(List<double> q) => (q[2] - bbox[2]).abs() < 1;
  bool onSide(String side, List<double> q) => switch (side) {
    'south' => south(q),
    'north' => north(q),
    'west' => west(q),
    _ => east(q),
  };
  const opposite = {
    'north': 'south',
    'south': 'north',
    'east': 'west',
    'west': 'east',
  };
  final backSide = opposite[item.facing] ?? 'north';
  final horizontal = backSide == 'north' || backSide == 'south';
  // the return is the part that does not span the whole back edge
  bool spans(List<double> q) => horizontal
      ? ((q[2] - q[0]) - (bbox[2] - bbox[0])).abs() < 1
      : ((q[3] - q[1]) - (bbox[3] - bbox[1])).abs() < 1;

  for (final q in item.parts) {
    p.layoutBox(q[0], q[1], q[2], q[3], 0, .3, cover);
    p.layoutBox(q[0] + 80, q[1] + 80, q[2] - 80, q[3] - 80, .3, .44, cushion);
    final sides = spans(q)
        ? [backSide]
        : [
            for (final s in const ['north', 'south', 'east', 'west'])
              if (s != item.facing && s != backSide && onSide(s, q)) s,
          ];
    for (final side in sides) {
      if (!onSide(side, q)) continue;
      if (side == 'north' || side == 'south') {
        final y0 = side == 'south' ? q[1] : q[3] - backT;
        p.layoutBox(q[0], y0, q[2], y0 + backT, 0, h / 1000, cover);
      } else {
        final x0 = side == 'west' ? q[0] : q[2] - backT;
        p.layoutBox(x0, q[1], x0 + backT, q[3], 0, h / 1000, cover);
      }
    }
  }
}

void _coffeeTable(_PieceCtx p) {
  final h = math.max(p.h, .3);
  const top = .035;
  const post = .022;
  final x = p.w / 2 - .05;
  final z = p.d / 2 - .05;
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2, h - top, h, _Finish.oak);
  p.box(
    -p.w / 2 + .07,
    p.w / 2 - .07,
    -p.d / 2 + .07,
    p.d / 2 - .07,
    .13,
    .148,
    _Finish.oak,
  );
  for (final su in const [-1.0, 1.0]) {
    for (final sv in const [-1.0, 1.0]) {
      p.box(
        su * x - post,
        su * x + post,
        sv * z - post,
        sv * z + post,
        0,
        h - top,
        _Finish.black,
      );
    }
  }
  if (p.carries) return;
  _books(p, -p.w * .2, 0.02, h, count: 3);
  _bowl(p, p.w * .22, -.02, h);
}

void _sideTable(_PieceCtx p) {
  final h = math.max(p.h, .35);
  final r = math.min(p.w, p.d) / 2 - .01;
  p.cyl(0, 0, r, h - .022, h, _Finish.oak);
  p.cyl(0, 0, .016, 0, h - .022, _Finish.black);
  p.cyl(0, 0, r * .58, 0, .014, _Finish.black);
  if (p.carries) return;
  if (p.index.isEven) {
    _plant(p, 0, 0, h);
  } else {
    _books(p, -.03, 0, h, count: 2);
  }
}

void _tvConsole(_PieceCtx p) {
  final h = math.max(p.h, .35);
  const leg = .13;
  p.legs(leg, _Finish.black, r: .014, inset: .05);
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2, leg, h, _Finish.oak);
  // slatted doors: a darker panel with the slats over it
  final doors = math.max(2, (p.w / .5).round());
  final dw = (p.w - .04) / doors;
  for (var i = 0; i < doors; i++) {
    final u0 = -p.w / 2 + .02 + dw * i;
    p.box(
      u0 + .004,
      u0 + dw - .004,
      p.d / 2,
      p.d / 2 + .008,
      leg + .02,
      h - .02,
      _Finish.oakDark,
    );
  }
  if (p.carries) return;
  p.box(
    -math.min(.4, p.w * .22),
    math.min(.4, p.w * .22),
    -p.d / 2 + .1,
    -p.d / 2 + .175,
    h,
    h + .055,
    const Color(0xFF232428),
  );
  _plant(p, p.w / 2 - .14, .02, h);
}

/// A flat screen hung on the wall behind it, its centre at the fixing height.
void _television(_PieceCtx p) {
  final high = p.h > .2 ? p.h : p.w * .56;
  final y0 = math.max((p.item.mountHeight ?? 1100) / 1000 - high / 2, .2);
  final wall = -p.d / 2;
  p.box(
    -p.w * .15,
    p.w * .15,
    wall,
    wall + .03,
    y0 + high * .3,
    y0 + high * .7,
    _Finish.black,
  );
  p.box(
    -p.w / 2,
    p.w / 2,
    wall + .03,
    wall + .058,
    y0,
    y0 + high,
    const Color(0xFF101114),
  );
  p.box(
    -p.w / 2 + .008,
    p.w / 2 - .008,
    wall + .058,
    wall + .06,
    y0 + .008,
    y0 + high - .008,
    _Finish.screen,
  );
}

void _bookshelf(_PieceCtx p) {
  final h = math.max(p.h, .6);
  const t = .025;
  p.box(-p.w / 2, p.w / 2, -p.d / 2, -p.d / 2 + .012, 0, h, _Finish.oakDark);
  for (final side in const [-1.0, 1.0]) {
    final u0 = side < 0 ? -p.w / 2 : p.w / 2 - t;
    p.box(u0, u0 + t, -p.d / 2, p.d / 2, 0, h, _Finish.oak);
  }
  final levels = math.max(3, (h / .36).round());
  final inner = p.w - 2 * t;
  final bay = (h - t) / levels - t;
  const spines = [
    Color(0xFF8C5A4A),
    Color(0xFF4E6E73),
    Color(0xFFC9A45C),
    Color(0xFF5B6B8C),
    Color(0xFF7D8F69),
  ];
  for (var i = 0; i <= levels; i++) {
    final y = (h - t) * i / levels;
    p.box(
      -inner / 2,
      inner / 2,
      -p.d / 2 + .006,
      p.d / 2 - .006,
      y,
      y + t,
      _Finish.oak,
    );
    if (i == levels) break;
    // a row of books standing from one end of the shelf
    var used = .01;
    final filled = inner * (.5 + ((p.index + i) % 3) * .1);
    var n = 0;
    while (used < filled) {
      final bw = .022 + ((n * 7 + i) % 4) * .008;
      final bh = math.min(bay - .02, .17 + ((n * 5 + i) % 4) * .03);
      final u0 = (i.isEven ? -1 : 1) * (inner / 2 - used - bw / 2) - bw / 2;
      final bd = math.min(p.d - .06, .13 + ((n * 3) % 3) * .02);
      p.box(
        u0,
        u0 + bw,
        -p.d / 2 + .03,
        -p.d / 2 + .03 + bd,
        y + t,
        y + t + bh,
        spines[(n + i) % spines.length],
      );
      used += bw + .002;
      n++;
    }
  }
}

/// A woven rug, lying flat.
void _rug(_PieceCtx p) {
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2,
    0,
    .012,
    _tone(_Finish.linen, -.06),
  );
  final inset = math.min(p.w, p.d) * .06;
  p.box(
    -p.w / 2 + inset,
    p.w / 2 - inset,
    -p.d / 2 + inset,
    p.d / 2 - inset,
    .012,
    .014,
    _Finish.linen,
  );
}

void _floorLamp(_PieceCtx p) {
  final h = math.max(p.h, 1.2);
  final r = math.min(p.w, p.d) / 2;
  p.cyl(0, 0, r * .6, 0, .02, _Finish.black);
  p.cyl(0, 0, .012, .02, h - .3, _Finish.black);
  p.cyl(0, 0, r, h - .3, h, const Color(0xFFFFE9C4));
}

// ── Things set down on the furniture ──

void _books(_PieceCtx p, double u, double v, double z, {int count = 2}) {
  const spines = [Color(0xFF8C5A4A), Color(0xFF4E6E73), Color(0xFFC9A45C)];
  for (var i = 0; i < count; i++) {
    p.box(
      u - .1,
      u + .1,
      v - .14,
      v + .14,
      z + i * .03,
      z + (i + 1) * .03,
      spines[(p.index + i) % spines.length],
    );
  }
}

void _bowl(_PieceCtx p, double u, double v, double z) {
  p.cyl(u, v, .09, z, z + .05, _Finish.terracotta);
}

void _plant(_PieceCtx p, double u, double v, double z) {
  p.cyl(u, v, .07, z, z + .12, _Finish.terracotta);
  p.cyl(u, v, .12, z + .12, z + .34, _Finish.plant);
}
