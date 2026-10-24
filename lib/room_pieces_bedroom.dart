part of 'main.dart';

// Bedroom furniture: the bed and what stands beside it, the wardrobe, the
// drawers, the dressing table, the desk and the lamps (the web's
// `scene3d/bedroom.ts` and `lights.ts`). Master bedrooms use the same pieces.

const _throws = [
  _Finish.sage,
  _Finish.terracotta,
  _Finish.mustard,
  _Finish.teal,
];
const _sheets = Color(0xFFF6F3EC);
const _warmLight = Color(0xFFFFE9C4);

final Map<String, _PieceBuilder> _bedroomPieces = {
  'bed': _bed,
  'bedside_table': _bedsideTable,
  'wardrobe': _wardrobe,
  'dresser': _dresser,
  'dressing_table': _dressingTable,
  'stool': _stool,
  'desk': _desk,
  'desk_chair': _deskChair,
  'bedside_lamp': _tableLamp,
  'desk_lamp': _deskLamp,
};

/// A grid of door or drawer fronts on the face of a piece, with a hairline
/// gap between; returns each front as `(u0, z0, width, height)`.
List<(double, double, double, double)> _fronts(
  _PieceCtx p,
  Color color, {
  required double u0,
  required double z0,
  required double width,
  required double height,
  required int cols,
  required int rows,
  double gap = .014,
}) {
  final fw = (width - gap * (cols - 1)) / cols;
  final fh = (height - gap * (rows - 1)) / rows;
  final face = p.d / 2;
  final out = <(double, double, double, double)>[];
  for (var c = 0; c < cols; c++) {
    for (var r = 0; r < rows; r++) {
      final u = u0 + c * (fw + gap);
      final z = z0 + r * (fh + gap);
      p.box(u, u + fw, face - .004, face + .016, z, z + fh, color);
      out.add((u, z, fw, fh));
    }
  }
  return out;
}

void _bed(_PieceCtx p) {
  final w = p.w;
  final d = p.d;
  final top = p.h.clamp(.45, .65); // the engine's height is the mattress top
  const board = .1; // what the headboard takes up at the wall
  final head = -d / 2 + board;
  final baseTop = top - .25;
  final cloth = _Finish.greige;
  final accent = _throws[p.index % _throws.length];

  p.legs(.1, _Finish.walnut, r: .03, inset: .08);
  p.box(-w / 2 - .02, w / 2 + .02, head, d / 2, .1, baseTop, _Finish.oak);
  p.box(
    -w / 2 + .02,
    w / 2 - .02,
    head + .03,
    d / 2 - .03,
    baseTop,
    top,
    _sheets,
  );

  // headboard: a padded board in upright channels
  const boardH = 1.1;
  p.box(-w / 2 - .04, w / 2 + .04, -d / 2, -d / 2 + board, 0, boardH, cloth);
  final channels = math.max(3, (w / .24).round());
  final cw = (w + .06) / channels;
  for (var i = 0; i < channels; i++) {
    final u0 = -(w + .06) / 2 + cw * i + .003;
    p.box(
      u0,
      u0 + cw - .006,
      -d / 2 + board,
      -d / 2 + board + .035,
      baseTop + .02,
      boardH - .02,
      _tone(cloth, .05),
    );
  }

  // pillows against the headboard, a cushion in front of each
  final sleepers = w > 1.3 ? 2 : 1;
  final pw = sleepers == 2 ? (w - .14) / 2 : math.min(w - .16, .72);
  for (var i = 0; i < sleepers; i++) {
    final u = sleepers == 2 ? (i == 0 ? -1 : 1) * (pw / 2 + .02) : 0.0;
    p.box(
      u - pw / 2,
      u + pw / 2,
      head + .02,
      head + .2,
      top,
      top + .3,
      _sheets,
    );
    final cu = math.min(pw * .72, .46);
    p.box(
      u - cu / 2,
      u + cu / 2,
      head + .24,
      head + .36,
      top,
      top + .28,
      i == 0 ? accent : _Finish.linen,
    );
  }

  // the duvet over the lower part of the bed, hanging over the sides and foot
  final fold = head + .52;
  p.box(
    -w / 2 - .015,
    w / 2 + .015,
    fold,
    d / 2 + .004,
    top - .0,
    top + .05,
    _Finish.linen,
  );
  for (final side in const [-1.0, 1.0]) {
    final u0 = side < 0 ? -w / 2 - .027 : w / 2 - .003;
    p.box(
      u0,
      u0 + .03,
      fold,
      d / 2 + .004,
      top - .24,
      top + .05,
      _tone(_Finish.linen, -.04),
    );
  }
  p.box(
    -w / 2 - .015,
    w / 2 + .015,
    d / 2 - .002,
    d / 2 + .03,
    top - .24,
    top + .05,
    _Finish.linen,
  );
  p.box(
    -w / 2 - .02,
    w / 2 + .02,
    fold,
    fold + .24,
    top + .05,
    top + .06,
    _sheets,
  );

  // a throw across the foot
  final across = d / 2 - .4;
  p.box(
    -w / 2 - .03,
    w / 2 + .03,
    across,
    across + .44,
    top + .05,
    top + .08,
    accent,
  );
  for (final side in const [-1.0, 1.0]) {
    final u0 = side < 0 ? -w / 2 - .056 : w / 2 + .03;
    p.box(u0, u0 + .026, across, across + .44, top - .22, top + .08, accent);
  }
}

void _bedsideTable(_PieceCtx p) {
  final h = math.max(p.h, .4);
  const leg = .17;
  p.legs(leg, _Finish.walnut, r: .016, inset: .035);
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2, leg, h, _Finish.oak);
  final drawers = _fronts(
    p,
    _tone(_Finish.oak, .05),
    u0: -p.w / 2 + .014,
    z0: leg + .014,
    width: p.w - .028,
    height: h - leg - .028,
    cols: 1,
    rows: 2,
  );
  for (final f in drawers) {
    p.box(
      f.$1 + f.$3 / 2 - .011,
      f.$1 + f.$3 / 2 + .011,
      p.d / 2 + .016,
      p.d / 2 + .036,
      f.$2 + f.$4 / 2 - .011,
      f.$2 + f.$4 / 2 + .011,
      _Finish.brass,
    );
  }
  if (p.carries) return;
  _books(p, -.03, 0, h, count: 2);
}

void _wardrobe(_PieceCtx p) {
  final h = math.max(p.h, 1.2);
  const plinth = .07;
  const frame = .022;
  final doors =
      int.tryParse(p.item.model ?? '') ?? math.max(2, (p.w / .5).round());
  p.box(
    -p.w / 2 + .02,
    p.w / 2 - .02,
    -p.d / 2 + .08,
    p.d / 2 - .03,
    0,
    plinth,
    _Finish.charcoal,
  );
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2 - .02, plinth, h, _Finish.oak);
  final fronts = _fronts(
    p,
    _Finish.white,
    u0: -p.w / 2 + frame,
    z0: plinth + frame,
    width: p.w - 2 * frame,
    height: h - plinth - 2 * frame,
    cols: doors,
    rows: 1,
    gap: .02,
  );
  for (var i = 0; i < fronts.length; i++) {
    final f = fronts[i];
    // doors open in pairs from where they meet; an odd last door opens alone
    final side = i.isEven && i < doors - 1 ? 1.0 : -1.0;
    final u = f.$1 + f.$3 / 2 + side * (f.$3 / 2 - .035);
    final z = f.$2 + math.min(1.0, f.$4 * .5);
    p.box(
      u - .008,
      u + .008,
      p.d / 2 + .016,
      p.d / 2 + .036,
      z - .15,
      z + .15,
      _Finish.black,
    );
  }
}

/// A chest of drawers.
void _dresser(_PieceCtx p) {
  final h = math.max(p.h, .5);
  const leg = .13;
  p.legs(leg, _Finish.walnut, r: .02, inset: .04);
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2, leg, h, _Finish.oak);
  final drawers = _fronts(
    p,
    _tone(_Finish.oak, .05),
    u0: -p.w / 2 + .016,
    z0: leg + .016,
    width: p.w - .032,
    height: h - leg - .032,
    cols: p.w >= .9 ? 2 : 1,
    rows: 3,
  );
  for (final f in drawers) {
    p.box(
      f.$1 + f.$3 / 2 - .012,
      f.$1 + f.$3 / 2 + .012,
      p.d / 2 + .016,
      p.d / 2 + .036,
      f.$2 + f.$4 / 2 - .012,
      f.$2 + f.$4 / 2 + .012,
      _Finish.brass,
    );
  }
  if (p.carries) return;
  _plant(p, -p.w * .28, -.02, h);
  _books(p, p.w * .2, -.2, h, count: 2);
}

/// A dressing table with its mirror; the engine's height is the mirror's top.
void _dressingTable(_PieceCtx p) {
  final total = math.max(p.h, 1.2);
  const table = .76;
  p.legs(table - .15, _Finish.oak, r: .018, inset: .03);
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2,
    table - .15,
    table - .022,
    _Finish.white,
  );
  p.box(
    -p.w / 2 - .01,
    p.w / 2 + .01,
    -p.d / 2 - .005,
    p.d / 2 + .005,
    table - .022,
    table,
    _Finish.oak,
  );
  final drawers = _fronts(
    p,
    _tone(_Finish.white, -.03),
    u0: -p.w / 2 + .015,
    z0: table - .14,
    width: p.w - .03,
    height: .105,
    cols: p.w > .9 ? 2 : 1,
    rows: 1,
    gap: .012,
  );
  for (final f in drawers) {
    p.box(
      f.$1 + f.$3 / 2 - .01,
      f.$1 + f.$3 / 2 + .01,
      p.d / 2 + .016,
      p.d / 2 + .034,
      f.$2 + f.$4 / 2 - .01,
      f.$2 + f.$4 / 2 + .01,
      _Finish.brass,
    );
  }

  // a mirror on a stand at the back
  final r = math.min(p.w * .3, (total - table - .06) / 2);
  final centre = table + .05 + r;
  final z = -p.d / 2 + .035;
  p.box(-.03, .03, z - .015, z + .015, table, table + .06, _Finish.brass);
  p.box(-r, r, z - .011, z + .011, centre - r, centre + r, _Finish.brass);
  p.box(
    -r + .014,
    r - .014,
    z + .011,
    z + .015,
    centre - r + .014,
    centre + r - .014,
    const Color(0xFFCFE0EA),
  );

  // a tray of bottles
  final u = p.w * .3;
  p.box(u - .12, u + .12, -.055, .095, table, table + .01, _Finish.brass);
  p.cyl(u - .06, .03, .018, table + .01, table + .085, const Color(0xFFD8B98A));
  p.box(
    u - .008,
    u + .028,
    -.018,
    .018,
    table + .01,
    table + .1,
    const Color(0xFFE7C9C4),
  );
  p.cyl(u + .07, .04, .022, table + .01, table + .06, _Finish.white);
}

/// A round upholstered stool on short brass legs.
void _stool(_PieceCtx p) {
  final h = math.max(p.h, .3);
  final r = math.min(p.w, p.d) / 2 - .01;
  const leg = .1;
  for (final su in const [-1.0, 1.0]) {
    for (final sv in const [-1.0, 1.0]) {
      final u = su * r * .55;
      final v = sv * r * .55;
      p.box(
        u - .009,
        u + .009,
        v - .009,
        v + .009,
        0,
        leg + .02,
        _Finish.brass,
      );
    }
  }
  p.cyl(0, 0, r * .98, leg, leg + .012, _Finish.brass);
  p.cyl(0, 0, r, leg + .012, h, _Finish.blush);
}

void _desk(_PieceCtx p) {
  final h = math.max(p.h, .6);
  const top = .03;
  const bar = .028;
  p.box(-p.w / 2, p.w / 2, -p.d / 2, p.d / 2, h - top, h, _Finish.oak);
  for (final side in const [-1.0, 1.0]) {
    // a steel loop at each end
    final u = side * (p.w / 2 - .06);
    for (final sv in const [-1.0, 1.0]) {
      final v = sv * (p.d / 2 - .06);
      p.box(
        u - bar / 2,
        u + bar / 2,
        v - bar / 2,
        v + bar / 2,
        0,
        h - top,
        _Finish.black,
      );
    }
    p.box(
      u - bar / 2,
      u + bar / 2,
      -p.d / 2 + .06,
      p.d / 2 - .06,
      h - top - bar,
      h - top,
      _Finish.black,
    );
    p.box(
      u - bar / 2,
      u + bar / 2,
      -p.d / 2 + .06,
      p.d / 2 - .06,
      0,
      bar,
      _Finish.black,
    );
  }
  // a drawer hung under the top
  final dw = math.min(.42, p.w * .38);
  final dx = p.w / 2 - .1 - dw / 2;
  p.box(
    dx - dw / 2,
    dx + dw / 2,
    -p.d / 2 + .07,
    p.d / 2 - .07,
    h - top - .1,
    h - top,
    _Finish.white,
  );
  p.box(
    dx - dw / 2 + .003,
    dx + dw / 2 - .003,
    p.d / 2 - .07,
    p.d / 2 - .056,
    h - top - .095,
    h - top - .005,
    _tone(_Finish.white, -.03),
  );
  if (p.carries) return;
  // a laptop, a mug and some books
  p.box(
    -p.w * .06 - .17,
    -p.w * .06 + .17,
    -.1,
    .1,
    h,
    h + .015,
    _Finish.charcoal,
  );
  p.box(
    -p.w * .06 - .17,
    -p.w * .06 + .17,
    -.12,
    -.1,
    h,
    h + .22,
    _Finish.charcoal,
  );
  p.cyl(p.w * .3, p.d * .12, .04, h, h + .09, _Finish.terracotta);
  _books(p, p.w * .32, -p.d * .22, h, count: 3);
}

/// A swivel chair on a five-star base, facing the desk.
void _deskChair(_PieceCtx p) {
  final h = math.max(p.h, .7);
  const seatH = .47;
  final reach = math.min(p.w, p.d) * .5 - .02;
  // the star base: a plus of two bars and a hub
  p.box(-reach, reach, -.016, .016, .04, .07, _Finish.black);
  p.box(-.016, .016, -reach, reach, .04, .07, _Finish.black);
  p.cyl(0, 0, .024, .07, seatH - .07, _Finish.black);
  p.cyl(0, 0, .1, seatH - .075, seatH - .045, _Finish.black);
  p.box(
    -p.w * .45,
    p.w * .45,
    -p.d * .43,
    p.d * .43,
    seatH - .045,
    seatH + .025,
    _Finish.charcoal,
  );
  p.box(
    -p.w * .42,
    p.w * .42,
    -p.d / 2 + .02,
    -p.d / 2 + .07,
    seatH + .01,
    h,
    _Finish.charcoal,
  );
}

/// A lamp with a pottery base and a drum shade.
void _tableLamp(_PieceCtx p) {
  final light = (p.item.mountHeight ?? 1000) / 1000;
  final foot = p.base ?? math.max(light - .4, 0);
  final body = math.max(light - foot - .1, .12);
  p.cyl(0, 0, .055, foot, foot + body, const Color(0xFFECE7DC));
  p.cyl(0, 0, .005, foot + body, foot + body + .04, _Finish.brass);
  p.cyl(0, 0, .1, foot + body + .02, foot + body + .18, _warmLight, rv: .1);
}

/// A jointed desk lamp, its head turned down over the work.
void _deskLamp(_PieceCtx p) {
  final light = (p.item.mountHeight ?? 1150) / 1000;
  final foot = p.base ?? math.max(light - .4, 0);
  final reach = math.max(light - foot, .25);
  p.cyl(0, 0, .065, foot, foot + .016, _Finish.black);
  p.box(
    -.007,
    .007,
    -.007,
    .007,
    foot + .016,
    foot + reach * .62,
    _Finish.black,
  );
  p.box(
    -.007,
    .007,
    -.07,
    .12,
    foot + reach * .62,
    foot + reach * .62 + .014,
    _Finish.black,
  );
  p.cyl(
    0,
    .12,
    .065,
    foot + reach - .06,
    foot + reach + .01,
    _Finish.black,
    rv: .065,
  );
  p.cyl(0, .12, .055, foot + reach - .064, foot + reach - .06, _warmLight);
}
