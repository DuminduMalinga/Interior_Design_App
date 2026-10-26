import 'dart:ui' show Offset, Rect;

/// Geometry for the rooms drawn over a floor plan. Every point is a fraction
/// (0-1) of the plan image's width and height, as the detector stores them
/// (`polygonPct` / `bboxPct`, divided by 100).

/// The corners of [r], clockwise from the top left: the outline of a room the
/// detector only boxed (the web's `boxCorners`).
List<Offset> rectCorners(Rect r) => [
  r.topLeft,
  r.topRight,
  r.bottomRight,
  r.bottomLeft,
];

/// Whether [point] is inside the polygon [outline] (ray casting), so an
/// L-shaped room counts only where it really is.
bool polygonContains(List<Offset> outline, Offset point) {
  if (outline.length < 3) return false;
  var inside = false;
  for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
    final a = outline[i];
    final b = outline[j];
    final crosses =
        (a.dy > point.dy) != (b.dy > point.dy) &&
        point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx;
    if (crosses) inside = !inside;
  }
  return inside;
}

/// The polygon's area, whatever the winding.
double polygonArea(List<Offset> outline) {
  var twice = 0.0;
  for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
    twice += outline[j].dx * outline[i].dy - outline[i].dx * outline[j].dy;
  }
  return twice.abs() / 2;
}

/// The centre of the polygon's bounding box.
Offset outlineCentre(List<Offset> outline) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in outline) {
    if (p.dx < minX) minX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Offset((minX + maxX) / 2, (minY + maxY) / 2);
}

/// A point inside the room to put its name on. The centre of an L or U shape
/// can fall outside it, so this prefers the area's balance point, then the
/// middle of the widest stretch across the room at its middle height, and
/// only then the bounding box's centre.
Offset outlineLabelPoint(List<Offset> outline) {
  if (outline.length < 3) return outlineCentre(outline);

  var twiceArea = 0.0, cx = 0.0, cy = 0.0;
  for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
    final cross = outline[j].dx * outline[i].dy - outline[i].dx * outline[j].dy;
    twiceArea += cross;
    cx += (outline[j].dx + outline[i].dx) * cross;
    cy += (outline[j].dy + outline[i].dy) * cross;
  }
  if (twiceArea.abs() > 1e-12) {
    final balance = Offset(cx / (3 * twiceArea), cy / (3 * twiceArea));
    if (polygonContains(outline, balance)) return balance;
  }

  final centre = outlineCentre(outline);
  final crossings = <double>[];
  for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
    final a = outline[i];
    final b = outline[j];
    if ((a.dy > centre.dy) != (b.dy > centre.dy)) {
      crossings.add(a.dx + (centre.dy - a.dy) * (b.dx - a.dx) / (b.dy - a.dy));
    }
  }
  crossings.sort();
  var widest = 0.0;
  Offset? best;
  for (var k = 0; k + 1 < crossings.length; k += 2) {
    final width = crossings[k + 1] - crossings[k];
    if (width > widest) {
      widest = width;
      best = Offset((crossings[k] + crossings[k + 1]) / 2, centre.dy);
    }
  }
  return best ?? centre;
}

/// Which room a tap at [point] landed in, or null for none. Where outlines
/// overlap, the smallest wins, so a small room inside a large one stays
/// reachable.
int? roomAt(List<List<Offset>> outlines, Offset point) {
  int? best;
  var bestArea = double.infinity;
  for (var i = 0; i < outlines.length; i++) {
    if (!polygonContains(outlines[i], point)) continue;
    final area = polygonArea(outlines[i]);
    if (area < bestArea) {
      best = i;
      bestArea = area;
    }
  }
  return best;
}
