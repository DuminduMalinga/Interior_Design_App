part of 'main.dart';

// The 3D viewer's furniture: each type the layout engines place is drawn as a
// few shaded solids (a sofa has legs, arms, a back, cushions), the way the web
// app's three.js models are built, instead of as one plain block. Each room's
// pieces live in `room_pieces_<room>.dart`; this file is the shared kit.

/// The finishes the models are made of (the web's `roomPalette3d.ts`).
abstract final class _Finish {
  static const oak = Color(0xFFCFA97C);
  static const oakDark = Color(0xFFAD875C);
  static const walnut = Color(0xFF77563C);
  static const white = Color(0xFFF4F1EB);
  static const linen = Color(0xFFE8E2D6);
  static const greige = Color(0xFFBDB5A8);
  static const charcoal = Color(0xFF3A3D42);
  static const black = Color(0xFF1D1E21);
  static const sage = Color(0xFF8FA48A);
  static const terracotta = Color(0xFFC77B5C);
  static const blush = Color(0xFFD9A59C);
  static const mustard = Color(0xFFD2A54A);
  static const teal = Color(0xFF5F8A87);
  static const caramel = Color(0xFFB0743E);
  static const brass = Color(0xFFC9A45C);
  static const steel = Color(0xFFDCDFE3);
  static const ceramic = Color(0xFFFAFAF6);
  static const glass = Color(0xFFBFD8E6);
  static const screen = Color(0xFF0B0F16);
  static const plant = Color(0xFF5E8A55);
}

/// The main colour of a furniture type; a plain block uses it.
Color _pieceColor(String type) => switch (type) {
  'sofa' || 'loveseat' || 'l_sofa' || 'bed' => _Finish.greige,
  'chair' => _Finish.teal,
  'reading_chair' => _Finish.caramel,
  'desk_chair' => _Finish.charcoal,
  'dining_chair' || 'stool' => _Finish.blush,
  'tv' => _Finish.black,
  'storage_cabinet' || 'sideboard' => _Finish.charcoal,
  'wardrobe' => _Finish.white,
  'rug' => _Finish.linen,
  'sink' || 'stove' || 'fridge' || 'grab_bar' => _Finish.steel,
  'toilet' || 'washbasin' => _Finish.ceramic,
  'lamp' ||
  'bedside_lamp' ||
  'desk_lamp' ||
  'pendant_light' => const Color(0xFFFFE9C4),
  _ => _Finish.oak,
};

/// An axis-aligned block (or a round column) in painter units.
class _Solid {
  const _Solid(
    this.x0,
    this.y0,
    this.x1,
    this.y1,
    this.z0,
    this.z1,
    this.color, {
    this.round = false,
  });

  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final double z0;
  final double z1;
  final Color color;

  /// An upright cylinder (an ellipse in the footprint) instead of a block.
  final bool round;

  double get cx => (x0 + x1) / 2;
  double get cy => (y0 + y1) / 2;

  /// A rug or mat: drawn before everything that stands on it.
  bool get flat => z1 <= 1.2 && (x1 - x0) > 8 && (y1 - y0) > 8;
}

/// Lighter or darker version of [c] (amount -1..1).
Color _tone(Color c, double amount) => amount >= 0
    ? Color.lerp(c, Colors.white, amount)!
    : Color.lerp(c, Colors.black, -amount)!;

typedef _PieceBuilder = void Function(_PieceCtx p);

/// What a builder draws with: the piece's size and position, and shorthand
/// for adding solids in the piece's own frame. Local `u` runs across the front
/// from the left to the right of someone facing it, `v` from the back to the
/// front, `z` up; all in metres and centred on the piece.
class _PieceCtx {
  _PieceCtx({
    required this.item,
    required this.k,
    required this.roomD,
    required this.index,
    this.base,
    this.carries = false,
  }) : right = _right[item.facing] ?? _right['south']!,
       front = _front[item.facing] ?? _front['south']! {
    final px0 = item.x0 * k;
    final px1 = item.x1 * k;
    final py0 = roomD - item.y1 * k;
    final py1 = roomD - item.y0 * k;
    cx = (px0 + px1) / 2;
    cy = (py0 + py1) / 2;
    final spanX = (item.x1 - item.x0) / 1000;
    final spanY = (item.y1 - item.y0) / 1000;
    final alongX = front.dy != 0;
    w = alongX ? spanX : spanY;
    d = alongX ? spanY : spanX;
    h = item.height / 1000;
  }

  // Painter space: x runs west to east, y north to south (the engine's y is
  // south to north, so it is flipped), so facing south is +y.
  static const _front = {
    'south': Offset(0, 1),
    'north': Offset(0, -1),
    'east': Offset(1, 0),
    'west': Offset(-1, 0),
  };
  static const _right = {
    'south': Offset(1, 0),
    'east': Offset(0, -1),
    'north': Offset(-1, 0),
    'west': Offset(0, 1),
  };

  final AnalysisFurniture item;

  /// Painter units per millimetre.
  final double k;
  final double roomD;

  /// Position in the layout; picks a cushion colour or a prop.
  final int index;

  /// For a lamp on a table or desk: the top of what it stands on, metres.
  final double? base;

  /// Something else stands on this piece, so it keeps its top clear.
  final bool carries;
  final Offset right;
  final Offset front;
  final List<_Solid> out = [];

  late final double cx;
  late final double cy;

  /// Across the front, front to back, and height: metres.
  late final double w;
  late final double d;
  late final double h;

  /// Painter units per metre.
  double get m => 1000 * k;

  /// A block from `u0..u1` across, `v0..v1` back to front and `z0..z1` up.
  void box(
    double u0,
    double u1,
    double v0,
    double v1,
    double z0,
    double z1,
    Color color,
  ) {
    final a = Offset(cx, cy) + (right * u0 + front * v0) * m;
    final b = Offset(cx, cy) + (right * u1 + front * v1) * m;
    out.add(
      _Solid(
        math.min(a.dx, b.dx),
        math.min(a.dy, b.dy),
        math.max(a.dx, b.dx),
        math.max(a.dy, b.dy),
        z0 * m,
        z1 * m,
        color,
      ),
    );
  }

  /// An upright cylinder of radius [r] at `u, v`.
  void cyl(
    double u,
    double v,
    double r,
    double z0,
    double z1,
    Color color, {
    double? rv,
  }) {
    final c = Offset(cx, cy) + (right * u + front * v) * m;
    final alongX = front.dy != 0;
    final rx = (alongX ? r : (rv ?? r)) * m;
    final ry = (alongX ? (rv ?? r) : r) * m;
    out.add(
      _Solid(
        c.dx - rx,
        c.dy - ry,
        c.dx + rx,
        c.dy + ry,
        z0 * m,
        z1 * m,
        color,
        round: true,
      ),
    );
  }

  /// A block given in the layout's own millimetres (`x` west to east, `y`
  /// south to north), for corner pieces drawn from their rectangles.
  void layoutBox(
    double x0,
    double y0,
    double x1,
    double y1,
    double z0,
    double z1,
    Color color,
  ) {
    out.add(
      _Solid(
        x0 * k,
        roomD - y1 * k,
        x1 * k,
        roomD - y0 * k,
        z0 * m,
        z1 * m,
        color,
      ),
    );
  }

  /// Four slim posts under a piece.
  void legs(
    double height,
    Color color, {
    double r = 0.022,
    double inset = .06,
  }) {
    if (height <= 0) return;
    for (final su in const [-1, 1]) {
      for (final sv in const [-1, 1]) {
        final u = su * (w / 2 - inset);
        final v = sv * (d / 2 - inset);
        box(u - r, u + r, v - r, v + r, 0, height, color);
      }
    }
  }
}

/// A plain block in the type's colour, for what no builder knows.
void _plainPiece(_PieceCtx p) {
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    p.d / 2,
    0,
    math.max(p.h, .05),
    _pieceColor(p.item.type),
  );
}

/// A fitting hung on the wall behind it, centred on its fixing height.
void _wallPanel(_PieceCtx p) {
  final high = p.h.clamp(.03, 1.4);
  final deep = p.d.clamp(.02, .08);
  final centre = (p.item.mountHeight ?? 1200) / 1000;
  p.box(
    -p.w / 2,
    p.w / 2,
    -p.d / 2,
    -p.d / 2 + deep,
    math.max(centre - high / 2, 0),
    math.max(centre - high / 2, 0) + high,
    _pieceColor(p.item.type),
  );
}

/// Which builder draws each furniture type. A room's file adds its own with
/// the `_<room>Pieces` maps merged here.
final Map<String, _PieceBuilder> _pieceBuilders = {
  ..._livingPieces,
  ..._bedroomPieces,
};

/// The solids of every piece of [furniture], in painter units.
List<_Solid> _buildFurniture(
  List<AnalysisFurniture> furniture, {
  required double k,
  required double roomD,
}) {
  final solids = <_Solid>[];
  // a lamp on a table or desk stands on the tallest piece under its centre
  AnalysisFurniture? hostOf(AnalysisFurniture lamp) {
    final x = (lamp.x0 + lamp.x1) / 2;
    final y = (lamp.y0 + lamp.y1) / 2;
    AnalysisFurniture? host;
    for (final other in furniture) {
      if (other == lamp || other.mounted != null && other.mounted != 'floor') {
        continue;
      }
      if (x >= other.x0 && x <= other.x1 && y >= other.y0 && y <= other.y1) {
        if (host == null || other.height > host.height) host = other;
      }
    }
    return host;
  }

  final hosts = <AnalysisFurniture, AnalysisFurniture>{
    for (final lamp in furniture)
      if (lamp.mounted == 'table') lamp: ?hostOf(lamp),
  };
  final carriers = hosts.values.toSet();
  for (var i = 0; i < furniture.length; i++) {
    final item = furniture[i];
    // ceiling lights and floor drains take up no room to draw
    if (item.mounted == 'ceiling' || item.mounted == 'drain') continue;
    final host = hosts[item];
    final p = _PieceCtx(
      item: item,
      k: k,
      roomD: roomD,
      index: i,
      base: host == null ? null : host.height / 1000,
      carries: carriers.contains(item),
    );
    final builder =
        _pieceBuilders[item.type] ??
        (item.mounted == 'wall' ? _wallPanel : _plainPiece);
    if (item.shape == 'l' && item.parts.isNotEmpty) {
      _cornerSofa(p);
    } else {
      builder(p);
    }
    solids.addAll(p.out);
  }
  return solids;
}
