import 'dart:math' as math;

/// Turning the room in the 3D view.

/// [angle] brought into the range -pi to pi, so a view that has been turned
/// round and round never grows without end.
double wrapAngle(double angle) {
  const turn = 2 * math.pi;
  final a = (angle + math.pi) % turn;
  return (a < 0 ? a + turn : a) - math.pi;
}

/// The two walls farthest from the camera when a room [width] by [depth] is
/// turned by [yaw]: the ones to stand up behind the furniture. The other two
/// are nearer the camera and would hide the room, so they show only as an
/// edge. The walls are `north`, `south`, `east` and `west`; north is where
/// y is 0 and west where x is 0, as the viewer draws them.
Set<String> farthestWalls(
  double yaw, {
  required double width,
  required double depth,
}) {
  final c = math.cos(yaw), s = math.sin(yaw);
  // how far down the screen a point falls: the larger, the nearer the camera
  double nearness(double x, double y) => x * (c + s) + y * (c - s);
  final d = {
    'north': nearness(width / 2, 0),
    'south': nearness(width / 2, depth),
    'west': nearness(0, depth / 2),
    'east': nearness(width, depth / 2),
  };
  final order = d.keys.toList()..sort((p, q) => d[p]!.compareTo(d[q]!));
  return {order[0], order[1]};
}
