part of 'main.dart';

// Bathroom fixtures and fittings: shower, toilet, basin, cabinet, mirror,
// towels and grab bars (the web's `scene3d/bathroom.ts`). The floor drain is
// too small to draw and is left out.

const _towels = [_Finish.sage, _Finish.terracotta, Color(0xFFE9E4DA)];
const _chrome = Color(0xFFECEEF0);
const _glassPane = Color(0x38CFE6EE);

final Map<String, _PieceBuilder> _bathroomPieces = {
  'shower': _shower,
  'toilet': _toilet,
  'washbasin': _basin,
  'bathroom_cabinet': _tallCabinet,
  'mirror': _mirror,
  'towel_rail': _towelRail,
  'towel_ring': _towelRing,
  'grab_bar': _grabBar,
};

bool _isLevel(AnalysisFurniture item) => (item.model ?? '').startsWith('level');

/// A mixer tap standing at height [z], its spout towards the front.
void _mixer(_PieceCtx p, double u, double v, double z, {double high = .16}) {
  p.cyl(u, v, .02, z, z + .02, _chrome);
  p.cyl(u, v, .013, z + .02, z + .02 + high, _chrome);
  p.box(
    u - .011,
    u + .011,
    v,
    v + .11,
    z + high + .008,
    z + high + .03,
    _chrome,
  );
}

/// A shower enclosure: a tray or a level floor, glass on the sides that are
/// not walls, and a rain head with its valve on the wall behind.
void _shower(_PieceCtx p) {
  final w = p.w;
  final d = p.d;
  final high = math.max(p.h, 1.9);
  final level = _isLevel(p.item);
  final floor = level ? .004 : .05;
  p.box(
    -w / 2,
    w / 2,
    -d / 2,
    d / 2,
    0,
    floor,
    level ? const Color(0xFFC9CDD0) : const Color(0xFFF6F6F3),
  );

  const pane = .008;
  void screen(double u0, double u1, double v0, double v1) {
    p.box(u0, u1, v0, v1, floor, floor + high, _glassPane);
    p.box(u0, u1, v0, v1, floor + high - .014, floor + high, _chrome);
  }

  final against = p.against;
  // a fixed screen on each side that is not a wall, and across part of the front
  if (against['left'] != true) screen(-w / 2, -w / 2 + pane, -d / 2, d / 2);
  if (against['right'] != true) screen(w / 2 - pane, w / 2, -d / 2, d / 2);
  if (against['front'] != true) {
    // the way in is left open beside the wall
    final fixed = math.max(w * .5, w - .7);
    final open = against['right'] == true && against['left'] != true
        ? 1.0
        : -1.0;
    final u0 = -open * (w - fixed) / 2 - fixed / 2;
    screen(u0, u0 + fixed, d / 2 - pane, d / 2);
  }

  // fittings on a wall the shower stands against
  final wall = against['back'] == true
      ? 'back'
      : against['left'] == true
      ? 'left'
      : against['right'] == true
      ? 'right'
      : null;
  if (wall == null) return;
  // `a` along the wall from its middle, `b` out from it, `z` up
  void fit(double a0, double a1, double b0, double b1, double z0, double z1) {
    switch (wall) {
      case 'back':
        p.box(a0, a1, -d / 2 + b0, -d / 2 + b1, z0, z1, _chrome);
      case 'left':
        p.box(-w / 2 + b0, -w / 2 + b1, a0, a1, z0, z1, _chrome);
      default:
        p.box(w / 2 - b1, w / 2 - b0, a0, a1, z0, z1, _chrome);
    }
  }

  fit(-.045, .045, 0, .012, 1.055, 1.145); // valve
  fit(-.011, .011, 0, .32, 2.0, 2.022); // arm
  fit(-.11, .11, .21, .43, 1.985, 1.997); // rain head
  fit(.131, .149, .02, .04, .95, 1.55); // rail with a hand shower
}

void _toilet(_PieceCtx p) {
  final h = math.max(p.h, .7);
  final rim = math.min(.43, h * .52); // top of the pan
  final wall = -p.d / 2;
  const china = _Finish.ceramic;
  // the cistern against the wall
  final tank = math.min(p.w * .95, .4);
  p.box(-tank / 2, tank / 2, wall, wall + .17, rim + .02, h - .03, china);
  p.box(
    -tank / 2 - .006,
    tank / 2 + .006,
    wall - .006,
    wall + .176,
    h - .03,
    h,
    china,
  );
  // the pan: a pedestal carrying an oval bowl and seat
  final length = p.d - .17;
  final cv = wall + .17 + length / 2 - .02;
  p.box(
    -p.w * .28,
    p.w * .28,
    cv - length * .44,
    cv + length * .28,
    0,
    rim - .1,
    china,
  );
  p.cyl(0, cv, p.w * .46, rim - .12, rim, china, rv: length / 2);
  p.cyl(
    0,
    cv,
    p.w * .46,
    rim,
    rim + .03,
    const Color(0xFFFDFDFB),
    rv: length / 2,
  );
}

/// A washbasin: a vanity cupboard with a bowl standing on it, or, for the
/// wall-hung models, a basin on brackets with the floor under it left clear.
void _basin(_PieceCtx p) {
  final h = math.max(p.h, .7);
  const china = _Finish.ceramic;
  final wall = -p.d / 2;

  if (!(p.item.model ?? '').startsWith('vanity')) {
    // an oval bowl running back to a ledge at the wall that carries the tap
    const deep = .16;
    final out = (p.d - .06) / 2;
    p.box(-p.w * .43, p.w * .43, wall, wall + .11, h - deep, h, china);
    p.cyl(0, wall + .06 + out, p.w / 2, h - deep, h, china, rv: out);
    _mixer(p, 0, wall + .05, h, high: .13);
    p.cyl(0, wall + .1, .017, h - deep - .2, h - deep, _chrome);
    return;
  }

  // a cupboard hung on the wall, clear of the floor
  const body = .5;
  final top = h - .1; // the counter the bowl stands on
  p.box(
    -p.w / 2,
    p.w / 2,
    wall,
    p.d / 2 - .02,
    top - .03 - body,
    top - .03,
    _Finish.oakDark,
  );
  p.box(
    -p.w / 2 - .005,
    p.w / 2 + .005,
    wall,
    p.d / 2 + .005,
    top - .03,
    top,
    const Color(0xFFECEBE6),
  );
  final fronts = _fronts(
    p,
    _Finish.oak,
    u0: -p.w / 2 + .003,
    z0: top - .03 - body + .003,
    width: p.w - .006,
    height: body - .006,
    cols: 1,
    rows: 2,
    gap: .018,
    face: p.d / 2 - .02,
  );
  for (final f in fronts) {
    _handle(
      p,
      f.$1 + f.$3 / 2,
      f.$2 + f.$4 - .04,
      math.min(.2, f.$3 * .4),
      p.d / 2 - .004,
      upright: false,
      color: _Finish.black,
    );
  }
  final r = math.min(.18, math.min(p.d / 2 - .08, p.w / 2 - .06));
  final u = p.w > .8 ? -p.w * .14 : 0.0;
  p.cyl(u, .04, r, top, top + .12, china);
  _mixer(p, u, wall + .06, top, high: .22);
  if (p.w > .8 && !p.carries) {
    _plant(p, p.w * .32, -.02, top);
    p.cyl(p.w * .14, wall + .09, .022, top, top + .1, _Finish.sage);
  }
}

/// A tall cupboard, hung clear of the floor like the vanity.
void _tallCabinet(_PieceCtx p) {
  final h = math.max(p.h, .8);
  const clear = .2;
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2 - .02, clear, h, _Finish.oakDark);
  final fronts = _fronts(
    p,
    _Finish.oak,
    u0: -p.w / 2 + .003,
    z0: clear + .003,
    width: p.w - .006,
    height: h - clear - .006,
    cols: 1,
    rows: 2,
    gap: .018,
    face: p.d / 2 - .02,
  );
  for (var i = 0; i < fronts.length; i++) {
    final f = fronts[i];
    _handle(
      p,
      f.$1 + f.$3 - .04,
      i == 0 ? f.$2 + f.$4 - .16 : f.$2 + .16,
      .2,
      p.d / 2 - .004,
      upright: true,
      color: _Finish.black,
    );
  }
}

/// A mirror on the wall behind it; the fixing height is its bottom edge.
void _mirror(_PieceCtx p) {
  final high = math.max(p.h, .3);
  final z0 = (p.item.mountHeight ?? 1100) / 1000;
  final wall = -p.d / 2;
  p.box(
    -p.w / 2 - .015,
    p.w / 2 + .015,
    wall,
    wall + .012,
    z0 - .015,
    z0 + high + .015,
    const Color(0xFFFFF6E6),
  );
  p.box(
    -p.w / 2,
    p.w / 2,
    wall + .012,
    wall + .042,
    z0,
    z0 + high,
    _Finish.black,
  );
  p.box(
    -p.w / 2 + .008,
    p.w / 2 - .008,
    wall + .042,
    wall + .045,
    z0 + .008,
    z0 + high - .008,
    const Color(0xFFCFE0EA),
  );
}

/// A bar on two brackets with a towel folded over it; the fixing height is the bar's.
void _towelRail(_PieceCtx p) {
  final z = (p.item.mountHeight ?? 1100) / 1000;
  final wall = -p.d / 2;
  const out = .07;
  p.box(
    -p.w / 2,
    p.w / 2,
    wall + out - .009,
    wall + out + .009,
    z - .009,
    z + .009,
    _chrome,
  );
  for (final side in const [-1.0, 1.0]) {
    final u = side * (p.w / 2 - .03);
    p.box(u - .008, u + .008, wall, wall + out, z - .008, z + .008, _chrome);
  }
  final towel = _towels[p.index % _towels.length];
  final across = p.w * .62;
  p.box(
    -across / 2,
    across / 2,
    wall + out + .002,
    wall + out + .024,
    z - .45,
    z,
    towel,
  );
  p.box(
    -across / 2,
    across / 2,
    wall + out - .024,
    wall + out - .002,
    z - .25,
    z,
    towel,
  );
  p.box(
    -across / 2,
    across / 2,
    wall + out - .025,
    wall + out + .025,
    z,
    z + .018,
    towel,
  );
}

/// A ring with a hand towel through it.
void _towelRing(_PieceCtx p) {
  final z = (p.item.mountHeight ?? 1100) / 1000;
  final wall = -p.d / 2;
  p.box(-.008, .008, wall, wall + .045, z + .082, z + .098, _chrome);
  p.box(-.085, .085, wall + .04, wall + .05, z - .085, z + .085, _chrome);
  final towel = _towels[(p.index + 1) % _towels.length];
  p.box(-.075, .075, wall + .047, wall + .067, z - .59, z - .02, towel);
}

/// A grab bar: along the wall behind it, or - when it is deeper than it is
/// wide - a rail that folds down from the wall beside the toilet.
void _grabBar(_PieceCtx p) {
  final z = (p.item.mountHeight ?? 700) / 1000;
  final wall = -p.d / 2;
  if (p.d > p.w * 1.5) {
    final end = p.d / 2 - .02;
    p.box(-.05, .05, wall, wall + .012, z - .31, z - .07, _Finish.steel);
    for (final drop in const [0.0, -.16]) {
      p.box(
        -.015,
        .015,
        wall,
        end,
        z + drop - .015,
        z + drop + .015,
        _Finish.steel,
      );
    }
    p.box(-.015, .015, end - .015, end, z - .175, z + .015, _Finish.steel);
    return;
  }
  final out = math.max(math.min(p.d, .1), .05);
  p.box(
    -p.w / 2,
    p.w / 2,
    wall + out - .016,
    wall + out + .016,
    z - .016,
    z + .016,
    _Finish.steel,
  );
  for (final side in const [-1.0, 1.0]) {
    final u = side * (p.w / 2 - .02);
    p.box(
      u - .014,
      u + .014,
      wall,
      wall + out,
      z - .014,
      z + .014,
      _Finish.steel,
    );
  }
}
