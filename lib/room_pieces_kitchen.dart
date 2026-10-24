part of 'main.dart';

// Kitchen units: base cabinets under a stone worktop, the sink, the cooker and
// the refrigerator (the web's `scene3d/kitchen.ts`).

const _plinth = .1;
const _worktop = .04;

/// How far the fronts stand in front of the carcass.
const _proud = .02;

final Map<String, _PieceBuilder> _kitchenPieces = {
  'counter': _counter,
  'utensil_drawers': _drawerUnit,
  'sink': _sink,
  'stove': _stove,
  'fridge': _fridge,
};

/// A handle on a front: a slim bar, upright or across.
void _handle(
  _PieceCtx p,
  double u,
  double z,
  double length,
  double out, {
  required bool upright,
  Color color = _Finish.steel,
}) {
  const t = .012;
  p.box(
    u - (upright ? t : length) / 2,
    u + (upright ? t : length) / 2,
    out,
    out + .02,
    z - (upright ? length : t) / 2,
    z + (upright ? length : t) / 2,
    color,
  );
}

/// Plinth, carcass and worktop of a base unit; [hollow] leaves the carcass
/// open that far down under the worktop, for a sink to hang in. Returns the
/// worktop height.
double _baseUnit(_PieceCtx p, {bool top = true, double hollow = 0}) {
  final h = math.max(p.h, .6);
  final full = h - _worktop - hollow;
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2 - .07,
    0,
    _plinth,
    _Finish.charcoal,
    early: hollow > 0,
  );
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2 - _proud,
    _plinth,
    full,
    _Finish.oakDark,
    early: hollow > 0,
  );
  if (hollow > 0) {
    const t = .018;
    for (final side in const [-1.0, 1.0]) {
      final u0 = side < 0 ? -p.w / 2 : p.w / 2 - t;
      p.box(
        u0,
        u0 + t,
        -p.d / 2,
        p.d / 2 - _proud,
        full,
        full + hollow,
        _Finish.oakDark,
      );
    }
  }
  if (top) {
    p.box(
      -p.w / 2,
      p.w / 2,
      -p.d / 2,
      p.d / 2 + .01,
      h - _worktop,
      h,
      _Finish.stone,
    );
  }
  return h;
}

/// Doors across a unit, one per 600 mm, under a row of drawers when [drawers].
void _unitFronts(_PieceCtx p, double h, {required bool drawers}) {
  final modules = math.max(1, (p.w / .6).round());
  final u0 = -p.w / 2 + .002;
  final width = p.w - .004;
  final y0 = _plinth + .004;
  var top = h - _worktop - .004;
  final out = p.d / 2 - _proud;
  if (drawers) {
    const high = .15;
    for (final f in _fronts(
      p,
      _Finish.oak,
      u0: u0,
      z0: top - high,
      width: width,
      height: high,
      cols: modules,
      rows: 1,
      gap: .004,
      face: out,
    )) {
      _handle(
        p,
        f.$1 + f.$3 / 2,
        f.$2 + f.$4 / 2,
        math.min(.16, f.$3 * .5),
        out + .016,
        upright: false,
      );
    }
    top -= high;
  }
  final doors = _fronts(
    p,
    _Finish.oak,
    u0: u0,
    z0: y0,
    width: width,
    height: top - y0,
    cols: modules,
    rows: 1,
    gap: .004,
    face: out,
  );
  for (var i = 0; i < doors.length; i++) {
    final f = doors[i];
    if (f.$3 <= .12) continue;
    final side = i.isEven && i < modules - 1 ? 1.0 : -1.0;
    _handle(
      p,
      f.$1 + f.$3 / 2 + side * (f.$3 / 2 - .04),
      f.$2 + f.$4 - .1,
      .14,
      out + .016,
      upright: true,
    );
  }
}

/// A stretch of worktop over cupboards; the piece in a corner has no front.
void _counter(_PieceCtx p) {
  if (p.item.role == 'corner') {
    _baseUnit(p);
    return;
  }
  final h = _baseUnit(p);
  _unitFronts(p, h, drawers: true);
  if (p.w < .5 || p.carries) return;
  switch (p.item.role) {
    case 'prep counter':
      p.box(-.17, .17, -.08, .16, h, h + .02, _Finish.walnut); // chopping board
      p.box(
        p.w / 2 - .165,
        p.w / 2 - .075,
        -p.d / 2 + .105,
        -p.d / 2 + .175,
        h,
        h + .2,
        _Finish.oakDark,
      );
    case 'serving counter':
      _bowl(p, 0, .02, h);
    default:
      _plant(p, 0, -p.d / 2 + .16, h);
  }
}

void _drawerUnit(_PieceCtx p) {
  final h = _baseUnit(p);
  final out = p.d / 2 - _proud;
  final fronts = _fronts(
    p,
    _Finish.oak,
    u0: -p.w / 2 + .002,
    z0: _plinth + .004,
    width: p.w - .004,
    height: h - _worktop - .004 - _plinth - .004,
    cols: 1,
    rows: 4,
    gap: .004,
    face: out,
  );
  for (final f in fronts) {
    _handle(
      p,
      f.$1 + f.$3 / 2,
      f.$2 + f.$4 - .045,
      math.min(.16, f.$3 * .5),
      out + .016,
      upright: false,
    );
  }
}

void _sink(_PieceCtx p) {
  final h = math.max(p.h, .6);
  const deep = .17;
  final bd = math.min(.4, p.d - .2); // bowl, front to back
  const bz = .03;
  // two bowls in a wide unit, a bowl and a drainer in a middling one, one in a narrow one
  final twin = p.w >= 1.1;
  final drainer = !twin && p.w >= .85;
  final bowls = twin
      ? [(-.24, .42), (.24, .42)]
      : drainer
      ? [(-p.w / 2 + .3, .44)]
      : [(0.0, math.min(.46, p.w - .14))];

  _baseUnit(p, top: false, hollow: deep + .01);
  _unitFronts(p, h, drawers: false);

  // the worktop in strips round the bowls
  final z0 = h - _worktop;
  final front = bz + bd / 2;
  final back = bz - bd / 2;
  var u = -p.w / 2;
  for (final b in bowls) {
    final left = b.$1 - b.$2 / 2;
    final right = b.$1 + b.$2 / 2;
    p.box(u, left, -p.d / 2, p.d / 2 + .01, z0, h, _Finish.stone);
    p.box(left, right, -p.d / 2, back, z0, h, _Finish.stone);
    p.box(left, right, front, p.d / 2 + .01, z0, h, _Finish.stone);
    // the steel bowl
    p.box(left, right, back, front, h - deep, h - deep + .004, _Finish.steel);
    p.box(left, left + .004, back, front, h - deep, h - .002, _Finish.steel);
    p.box(right - .004, right, back, front, h - deep, h - .002, _Finish.steel);
    p.box(left, right, back, back + .004, h - deep, h - .002, _Finish.steel);
    p.box(left, right, front - .004, front, h - deep, h - .002, _Finish.steel);
    u = right;
  }
  p.box(u, p.w / 2, -p.d / 2, p.d / 2 + .01, z0, h, _Finish.stone);
  if (drainer) {
    final from = bowls.first.$1 + bowls.first.$2 / 2 + .05;
    p.box(from, p.w / 2 - .05, back, front, h, h + .003, _Finish.steel);
  }

  // a swan-neck tap behind the bowls
  final tx = twin ? 0.0 : bowls.first.$1;
  final tz = bz - bd / 2 - .055;
  const chrome = Color(0xFFECEEF0);
  p.cyl(tx, tz, .024, h, h + .035, chrome);
  p.cyl(tx, tz, .012, h + .035, h + .275, chrome);
  p.box(tx - .012, tx + .012, tz, tz + .15, h + .263, h + .287, chrome);
  p.cyl(tx, tz + .15, .012, h + .235, h + .275, chrome);
}

void _stove(_PieceCtx p) {
  final h = math.max(p.h, .6);
  const black = Color(0xFF16171A);
  const iron = Color(0xFF232427);
  final face = p.d / 2 - _proud;
  const t = _proud - .002;

  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2 - .07,
    0,
    _plinth,
    _Finish.charcoal,
  );
  p.box(-p.w / 2, p.w / 2, -p.d / 2, face, _plinth, h - .012, _Finish.steel);
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2 + .01, h - .012, h, _Finish.steel);

  // the front: a drawer, the oven door with its window, and the controls above
  final top = h - .016;
  const controls = .1;
  const drawer = .11;
  const y0 = _plinth + drawer + .008;
  final y1 = top - controls - .006;
  final out = face + t;
  p.box(
    -p.w / 2 + .002,
    p.w / 2 - .002,
    face,
    out,
    _plinth + .004,
    _plinth + .004 + drawer,
    _tone(_Finish.steel, -.03),
  );
  p.box(-p.w / 2 + .002, p.w / 2 - .002, face, out, y0, y1, _Finish.steel);
  p.box(
    -p.w / 2 + .06,
    p.w / 2 - .06,
    out,
    out + .003,
    y0 + .05,
    y1 - .1,
    const Color(0xFF0C0D10),
  );
  _handle(p, 0, y1 - .045, p.w - .1, out, upright: false);
  p.box(
    -p.w / 2 + .002,
    p.w / 2 - .002,
    face,
    out,
    top - controls,
    top,
    _Finish.steel,
  );
  final knobs = p.w >= .85 ? 6 : 5;
  for (var i = 0; i < knobs; i++) {
    final u = -p.w / 2 + p.w * (i + .5) / knobs;
    p.box(
      u - .017,
      u + .017,
      out,
      out + .022,
      top - controls / 2 - .017,
      top - controls / 2 + .017,
      black,
    );
  }

  // the hob
  p.box(
    -p.w / 2 + .04,
    p.w / 2 - .04,
    -p.d / 2 + .06,
    p.d / 2 - .06,
    h,
    h + .006,
    black,
  );
  final dx = math.min(.26, p.w * .22);
  final rings = [
    (-dx, -.12, 1.0),
    (dx, -.12, .85),
    (-dx, .12, .85),
    (dx, .12, 1.0),
    if (p.w >= .85) (0.0, 0.0, 1.15),
  ];
  for (final (u, v, size) in rings) {
    p.cyl(u, v, .06 * size, h + .006, h + .012, _Finish.steel);
    p.cyl(u, v, .03 * size, h + .008, h + .022, iron);
  }
}

void _fridge(_PieceCtx p) {
  final h = math.max(p.h, 1.0);
  const door = .045;
  const bar = Color(0xFF9A9DA2);
  final face = p.d / 2 - door;
  p.box(
    -p.w / 2 + .01,
    p.w / 2 - .01,
    -p.d / 2,
    p.d / 2 - .1,
    0,
    .03,
    _Finish.black,
  );
  p.box(-p.w / 2, p.w / 2, -p.d / 2, face, .03, h, _tone(_Finish.steel, -.25));
  void leaf(double u0, double u1, double z0, double z1) => p.box(
    u0 + .003,
    u1 - .003,
    face,
    face + door,
    z0 + .003,
    z1 - .003,
    _Finish.steel,
  );

  if (p.w >= .85) {
    // two doors over a freezer drawer
    final split = .03 + (h - .03) * .36;
    leaf(-p.w / 2, 0, split, h);
    leaf(0, p.w / 2, split, h);
    leaf(-p.w / 2, p.w / 2, .03, split);
    for (final side in const [-1.0, 1.0]) {
      _handle(
        p,
        side * .045,
        split + (h - split) * .45,
        math.min(.7, (h - split) * .6),
        p.d / 2 - .004,
        upright: true,
        color: bar,
      );
    }
    _handle(
      p,
      0,
      split - .09,
      p.w * .6,
      p.d / 2 - .004,
      upright: false,
      color: bar,
    );
  } else {
    // a freezer door over the main one
    final split = .03 + (h - .03) * .68;
    leaf(-p.w / 2, p.w / 2, .03, split);
    leaf(-p.w / 2, p.w / 2, split, h);
    _handle(
      p,
      -p.w / 2 + .06,
      split - .34,
      .5,
      p.d / 2 - .004,
      upright: true,
      color: bar,
    );
    _handle(
      p,
      -p.w / 2 + .06,
      split + .2,
      .24,
      p.d / 2 - .004,
      upright: true,
      color: bar,
    );
  }
}
