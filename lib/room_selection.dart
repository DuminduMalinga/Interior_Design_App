part of 'main.dart';

/// Shown after [ProcessingScreen] finishes analyzing the uploaded floor plan.
///
/// Presents the AI-detected rooms as an interactive top-down diagram plus a
/// list of tappable cards, each annotated with an AI "suitability" score so
/// the user can judge how well a room fits before continuing.
class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({super.key});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

/// Which theme colour a detected room is drawn in.
enum _RoomAccent {
  primary,
  secondary,
  accent;

  Color resolve(AppColors c) => switch (this) {
    primary => c.primary,
    secondary => c.secondary,
    accent => c.accent,
  };
}

/// Maps an AI score (0-100) to a status colour: strong, good or fair.
AppStatus _scoreStatus(int score) {
  if (score >= 90) return AppStatus.success;
  if (score >= 75) return AppStatus.info;
  return AppStatus.warning;
}

class _DetectedRoom {
  const _DetectedRoom({
    required this.name,
    required this.icon,
    required this.accent,
    required this.bounds,
    required this.suitability,
    required this.note,
  });

  final String name;
  final IconData icon;
  final _RoomAccent accent;

  /// Fractional bounds (0-1) within the floor plan diagram.
  final Rect bounds;

  /// AI confidence/suitability score out of 100.
  final int suitability;
  final String note;

  Color colorIn(AppColors c) => accent.resolve(c);

  String get tag {
    if (suitability >= 90) return 'Excellent fit';
    if (suitability >= 75) return 'Great fit';
    return 'Good fit';
  }
}

const _detectedRooms = [
  _DetectedRoom(
    name: 'Living Room',
    icon: Icons.weekend_outlined,
    accent: _RoomAccent.primary,
    bounds: Rect.fromLTWH(0, 0, .58, .62),
    suitability: 96,
    note: 'Bright, open layout — ideal for a statement centerpiece.',
  ),
  _DetectedRoom(
    name: 'Kitchen',
    icon: Icons.kitchen_outlined,
    accent: _RoomAccent.accent,
    bounds: Rect.fromLTWH(.6, 0, .4, .38),
    suitability: 88,
    note: 'Efficient galley shape close to the dining area.',
  ),
  _DetectedRoom(
    name: 'Bedroom',
    icon: Icons.bed_outlined,
    accent: _RoomAccent.secondary,
    bounds: Rect.fromLTWH(.6, .42, .4, .58),
    suitability: 74,
    note: 'Cozy corner room with limited natural light.',
  ),
];

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final room = _detectedRooms[_selected];
    final wide = !context.screenSize.isMobile;

    final diagram = _FloorPlanDiagram(
      rooms: _detectedRooms,
      selected: _selected,
      onSelect: (i) => setState(() => _selected = i),
    );
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detected rooms', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _detectedRooms.length; i++) ...[
          _RoomCard(
            room: _detectedRooms[i],
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
          if (i != _detectedRooms.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Design the ${room.name}',
          icon: Icons.auto_awesome_rounded,
          onPressed: () => _openLayouts(context, room),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Select a room'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AiPill(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We found 3 rooms',
                    style: context.responsive(
                      mobile: text.headlineMedium,
                      tablet: text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap a room on the plan or in the list to see how well it '
                    'suits an AI redesign.',
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: diagram),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(flex: 4, child: list),
                      ],
                    )
                  else ...[
                    diagram,
                    const SizedBox(height: AppSpacing.xl),
                    list,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLayouts(BuildContext context, _DetectedRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LayoutsScreen(room: room)),
    );
  }
}

/// Interactive top-down floor plan with each detected room drawn as a
/// distinct colored overlay. Tapping a region selects that room.
class _FloorPlanDiagram extends StatelessWidget {
  const _FloorPlanDiagram({
    required this.rooms,
    required this.selected,
    required this.onSelect,
  });

  final List<_DetectedRoom> rooms;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AspectRatio(
      aspectRatio: 1.05,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Hit-testing uses the painted area, which is inset by the padding.
          const padding = AppSpacing.lg;
          final size = Size(
            constraints.maxWidth - padding * 2,
            constraints.maxHeight - padding * 2,
          );
          return GestureDetector(
            onTapUp: (details) {
              final local = details.localPosition - const Offset(padding, padding);
              for (var i = rooms.length - 1; i >= 0; i--) {
                final rect = Rect.fromLTWH(
                  rooms[i].bounds.left * size.width,
                  rooms[i].bounds.top * size.height,
                  rooms[i].bounds.width * size.width,
                  rooms[i].bounds.height * size.height,
                );
                if (rect.contains(local)) {
                  onSelect(i);
                  return;
                }
              }
            },
            child: AppCard(
              radius: AppRadius.xlAll,
              padding: const EdgeInsets.all(padding),
              child: CustomPaint(
                painter: _FloorPlanPainter(
                  rooms: rooms,
                  selected: selected,
                  colors: c,
                  labelStyle: context.text.labelSmall!,
                ),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter({
    required this.rooms,
    required this.selected,
    required this.colors,
    required this.labelStyle,
  });

  final List<_DetectedRoom> rooms;
  final int selected;
  final AppColors colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = colors.textPrimary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(Offset.zero & size, outline);

    for (var i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final color = room.colorIn(colors);
      final isSelected = i == selected;
      final rect = Rect.fromLTWH(
        room.bounds.left * size.width,
        room.bounds.top * size.height,
        room.bounds.width * size.width,
        room.bounds.height * size.height,
      ).deflate(2.5);

      if (isSelected) {
        final glow = Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawRect(rect, glow);
      }

      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: isSelected ? 0.30 : 0.14),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 1 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.4 : 1.2,
      );

      _paintLabel(canvas, rect, room, color, isSelected);
    }
  }

  void _paintLabel(
    Canvas canvas,
    Rect rect,
    _DetectedRoom room,
    Color color,
    bool isSelected,
  ) {
    final iconSpan = TextSpan(
      text: String.fromCharCode(room.icon.codePoint),
      style: TextStyle(
        fontSize: AppIconSize.sm,
        fontFamily: room.icon.fontFamily,
        package: room.icon.fontPackage,
        color: colors.onPrimary,
      ),
    );
    final labelSpan = TextSpan(
      text: '  ${room.name}',
      style: labelStyle.copyWith(color: colors.onPrimary),
    );
    final painter = TextPainter(
      text: TextSpan(children: [iconSpan, labelSpan]),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 12);

    final pillWidth = painter.width + 16;
    final pillHeight = painter.height + 10;
    if (pillWidth > rect.width + 4) return;

    final pillRect = Rect.fromLTWH(
      rect.left + 7,
      rect.top + 7,
      pillWidth,
      pillHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = color.withValues(alpha: isSelected ? 0.9 : 0.55),
    );
    painter.paint(canvas, pillRect.topLeft + const Offset(8, 5));
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.rooms != rooms ||
      oldDelegate.colors != colors ||
      oldDelegate.labelStyle != labelStyle;
}

/// A tappable card summarizing a detected room and its AI suitability score.
class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  final _DetectedRoom room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final color = room.colorIn(c);
    final status = _scoreStatus(room.suitability);
    final scoreColor = status.colorIn(c);

    return AppCard(
      onTap: onTap,
      color: selected ? c.primary.withValues(alpha: 0.08) : null,
      borderColor: selected ? c.primary.withValues(alpha: 0.55) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(room.icon, color: color, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(room.name, style: text.titleSmall)),
                    AppStatusChip(
                      label: '${room.suitability}% match',
                      status: status,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  room.tag,
                  style: text.labelMedium?.copyWith(color: scoreColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  room.note,
                  style: text.bodySmall?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.fullAll,
                  child: LinearProgressIndicator(
                    value: room.suitability / 100,
                    minHeight: 5,
                    backgroundColor: c.glassFill,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? c.primary : c.border,
            size: 20,
          ),
        ],
      ),
    );
  }
}
