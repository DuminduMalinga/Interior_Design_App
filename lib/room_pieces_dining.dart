part of 'main.dart';

// Dining furniture: the table, its chairs and the sideboard (the web's
// `scene3d/dining.ts`).

final Map<String, _PieceBuilder> _diningPieces = {
  'dining_table': _diningTable,
  'dining_chair': _diningChair,
  'sideboard': (p) => _cupboard(p, withLamp: true),
  'storage_cabinet': (p) => _cupboard(p, withLamp: false),
};

void _diningTable(_PieceCtx p) {
  final w = p.w;
  final d = p.d;
  final h = math.max(p.h, .6);
  const top = .04;
  const inset = .09;
  p.box(-w / 2, w / 2, -d / 2, d / 2, h - top, h, _Finish.oak);
  // rails under the top, and a tapered leg at each corner
  final rail = _Finish.oakDark;
  for (final sv in const [-1.0, 1.0]) {
    final v = sv * (d / 2 - inset);
    p.box(
      -(w / 2 - inset - .02),
      w / 2 - inset - .02,
      v - .011,
      v + .011,
      h - top - .07,
      h - top,
      rail,
    );
  }
  for (final su in const [-1.0, 1.0]) {
    final u = su * (w / 2 - inset);
    p.box(
      u - .011,
      u + .011,
      -(d / 2 - inset - .02),
      d / 2 - inset - .02,
      h - top - .07,
      h - top,
      rail,
    );
  }
  for (final su in const [-1.0, 1.0]) {
    for (final sv in const [-1.0, 1.0]) {
      final u = su * (w / 2 - inset);
      final v = sv * (d / 2 - inset);
      p.box(u - .02, u + .02, v - .02, v + .02, 0, h - top, _Finish.oak);
    }
  }
  if (p.carries) return;
  final long = math.max(w, d);
  if (long < 1.1) {
    _bowl(p, 0, 0, h);
  } else {
    _vase(p, 0, 0, h);
    if (long >= 1.7) {
      _bowl(p, w >= d ? long * .24 : 0, w >= d ? 0 : long * .24, h);
    }
  }
}

/// A chair with an upholstered seat and back on a timber frame, its front
/// towards the table.
void _diningChair(_PieceCtx p) {
  final h = math.max(p.h, .7);
  final d = math.min(p.d, .52);
  const seatH = .46;
  final sw = p.w * .9;
  final sd = d * .82;
  final x = sw / 2 - .03;
  final back = -d / 2 + .05;
  final front = back + sd - .04;
  for (final su in const [-1.0, 1.0]) {
    final u = su * x;
    p.box(
      u - .015,
      u + .015,
      front - .015,
      front + .015,
      0,
      seatH - .05,
      _Finish.oak,
    );
    p.box(
      u - .015,
      u + .015,
      back - .015,
      back + .015,
      0,
      seatH - .05,
      _Finish.oak,
    );
    // carried up to the back
    p.box(
      u - .015,
      u + .015,
      back - .05,
      back - .02,
      seatH - .05,
      h - .03,
      _Finish.oak,
    );
  }
  final middle = back + sd / 2 - .02;
  p.box(
    -sw / 2 + .01,
    sw / 2 - .01,
    middle - sd / 2,
    middle + sd / 2,
    seatH - .065,
    seatH - .045,
    _Finish.oak,
  );
  p.box(
    -sw / 2,
    sw / 2,
    middle - sd / 2,
    middle + sd / 2,
    seatH - .05,
    seatH,
    _Finish.blush,
  );
  p.box(
    -sw / 2 + .005,
    sw / 2 - .005,
    back - .04,
    back - .005,
    h - .45,
    h - .05,
    _Finish.blush,
  );
}

/// A low cupboard on legs: doors, a timber top, and something standing on it.
void _cupboard(_PieceCtx p, {required bool withLamp}) {
  final h = math.max(p.h, .4);
  final leg = h > 1.0 ? .1 : .16;
  const top = .025;
  final w = p.w;
  final d = p.d;
  p.legs(leg, _Finish.oak, r: .02, inset: .04);
  p.box(
    -w / 2,
    w / 2,
    -d / 2,
    d / 2,
    leg,
    h - top,
    _tone(_Finish.charcoal, -.25),
  );
  p.box(
    -w / 2 - .01,
    w / 2 + .01,
    -d / 2,
    d / 2 + .0075,
    h - top,
    h,
    _Finish.oak,
  );
  final doors = math.max(2, (w / .47).round());
  final faces = _fronts(
    p,
    _Finish.charcoal,
    u0: -w / 2 + .006,
    z0: leg + .006,
    width: w - .012,
    height: h - leg - top - .012,
    cols: doors,
    rows: h > 1.2 ? 2 : 1,
    gap: .018,
  );
  for (var i = 0; i < faces.length; i++) {
    final f = faces[i];
    final col = i ~/ (h > 1.2 ? 2 : 1);
    final side = col.isEven && col < doors - 1 ? 1.0 : -1.0;
    final u = f.$1 + f.$3 / 2 + side * (f.$3 / 2 - .04);
    final z = f.$2 + f.$4 - .08;
    p.box(
      u - .012,
      u + .012,
      d / 2 + .016,
      d / 2 + .04,
      z - .012,
      z + .012,
      _Finish.brass,
    );
  }
  if (p.carries || h > 1.3) return;
  if (withLamp) {
    final u = -w / 2 + .2;
    p.cyl(u, 0, .05, h, h + .25, const Color(0xFFECE7DC));
    p.cyl(u, 0, .11, h + .2, h + .38, const Color(0xFFFFE9C4));
  } else {
    _plant(p, -w / 2 + .18, 0, h);
  }
  _books(p, w * .08, .02, h, count: 2);
  if (w > 1.1) _vase(p, w / 2 - .2, -.02, h);
}

void _vase(_PieceCtx p, double u, double v, double z) {
  p.cyl(u, v, .06, z, z + .2, _Finish.teal);
  p.cyl(u, v, .02, z + .2, z + .3, _Finish.teal);
}
