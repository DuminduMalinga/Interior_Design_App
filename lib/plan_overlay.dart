import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'data/plan_geometry.dart';

/// One room's outline on the plan, and whether it can be picked.
class PlanOverlayRoom {
  const PlanOverlayRoom({
    required this.name,
    required this.outline,
    required this.selectable,
  });

  final String name;

  /// Corners as fractions (0-1) of the plan image's width and height.
  final List<Offset> outline;

  /// False for rooms no layout engine covers yet: they are drawn faintly and
  /// cannot be chosen.
  final bool selectable;
}

/// The uploaded floor plan with each detected room drawn over it, as the
/// web's room-selection screen shows it. Tapping a room picks it; each room
/// is its own outline, so an L-shaped room is an L and neighbours don't
/// overlap.
class PlanOverlay extends StatelessWidget {
  const PlanOverlay({
    super.key,
    required this.rooms,
    required this.aspectRatio,
    required this.selected,
    required this.onSelect,
    required this.onBlocked,
    this.imageUrl,
    this.counts = const {},
  });

  final List<PlanOverlayRoom> rooms;

  /// Width over height of the plan image, so the outlines line up with it.
  final double aspectRatio;

  /// Index into [rooms] of the chosen room, if any.
  final int? selected;

  /// A selectable room was tapped.
  final ValueChanged<int> onSelect;

  /// A room that can't be furnished was tapped.
  final ValueChanged<int> onBlocked;

  /// Where to load the plan image from; without it the outlines are still
  /// drawn, on a blank sheet.
  final String? imageUrl;

  /// What the detector found, by kind (Wall, Room, Door, Window).
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final url = imageUrl;

    // A small note along the bottom, so it stays clear of the outlines.
    Widget noPreview() => Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Text(
          'No preview available',
          style: text.labelSmall?.copyWith(color: c.textMuted),
        ),
      ),
    );

    return Semantics(
      container: true,
      label:
          'Floor plan with ${rooms.length} rooms. '
          'Tap a room on the plan, or choose from the list below.',
      child: AppCard(
        radius: AppRadius.xlAll,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: AppRadius.lgAll,
              // Plans are drawn on white, so the sheet is white in both themes.
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          final at = Offset(
                            details.localPosition.dx / size.width,
                            details.localPosition.dy / size.height,
                          );
                          final i = roomAt([
                            for (final room in rooms) room.outline,
                          ], at);
                          if (i == null) return;
                          if (rooms[i].selectable) {
                            onSelect(i);
                          } else {
                            onBlocked(i);
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (url == null)
                              noPreview()
                            else
                              Image.network(
                                url,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                                excludeFromSemantics: true,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      ),
                                errorBuilder: (context, error, stack) =>
                                    noPreview(),
                              ),
                            CustomPaint(
                              painter: PlanOverlayPainter(
                                rooms: rooms,
                                selected: selected,
                                colors: c,
                                labelStyle: text.labelSmall!,
                              ),
                              size: Size.infinite,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (counts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final (key, label) in const [
                    ('Wall', 'Walls'),
                    ('Room', 'Rooms'),
                    ('Door', 'Doors'),
                    ('Window', 'Windows'),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text('${counts[key] ?? 0}', style: text.titleMedium),
                          Text(
                            label,
                            style: text.labelSmall?.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Draws the room outlines: the chosen room filled and labelled, other
/// pickable rooms outlined so touch users can see what to tap, and rooms that
/// can't be furnished only faintly.
class PlanOverlayPainter extends CustomPainter {
  const PlanOverlayPainter({
    required this.rooms,
    required this.selected,
    required this.colors,
    required this.labelStyle,
  });

  final List<PlanOverlayRoom> rooms;
  final int? selected;
  final AppColors colors;
  final TextStyle labelStyle;

  Path _pathOf(List<Offset> outline, Size size) {
    final path = Path();
    for (var i = 0; i < outline.length; i++) {
      final p = Offset(outline[i].dx * size.width, outline[i].dy * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      if (room.outline.length < 3) continue;
      final path = _pathOf(room.outline, size);
      final isSelected = i == selected;

      if (!room.selectable) {
        canvas.drawPath(
          path,
          Paint()
            ..color = colors.textMuted.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        continue;
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = colors.primary.withValues(alpha: isSelected ? 0.30 : 0.07),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.primary.withValues(alpha: isSelected ? 1 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.4 : 1.2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final chosen = selected;
    if (chosen != null && chosen >= 0 && chosen < rooms.length) {
      _paintLabel(canvas, size, rooms[chosen]);
    }
  }

  /// The chosen room's name on a pill at the middle of its outline.
  void _paintLabel(Canvas canvas, Size size, PlanOverlayRoom room) {
    if (room.outline.length < 3) return;
    final centre = outlineLabelPoint(room.outline);
    final painter = TextPainter(
      text: TextSpan(
        text: room.name,
        style: labelStyle.copyWith(color: colors.onPrimary),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 24);

    final pill = Rect.fromCenter(
      center: Offset(centre.dx * size.width, centre.dy * size.height),
      width: painter.width + 16,
      height: painter.height + 10,
    );
    // keep the pill on the plan, whatever the room's position
    final inside = pill.shift(
      Offset(
        pill.left < 4
            ? 4 - pill.left
            : (pill.right > size.width - 4 ? size.width - 4 - pill.right : 0),
        pill.top < 4
            ? 4 - pill.top
            : (pill.bottom > size.height - 4
                  ? size.height - 4 - pill.bottom
                  : 0),
      ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inside, const Radius.circular(10)),
      Paint()..color = colors.primary.withValues(alpha: 0.92),
    );
    painter.paint(canvas, inside.topLeft + const Offset(8, 5));
  }

  @override
  bool shouldRepaint(covariant PlanOverlayPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.rooms != rooms ||
      oldDelegate.colors != colors ||
      oldDelegate.labelStyle != labelStyle;
}
