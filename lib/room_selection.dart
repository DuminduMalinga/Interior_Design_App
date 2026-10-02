part of 'main.dart';

/// Shown after [ProcessingScreen] finishes analyzing the uploaded floor plan.
///
/// Presents the AI-detected rooms (the `Room` rows a backend pipeline wrote
/// for [floorPlan]) as an interactive top-down diagram plus a list of
/// tappable cards, each annotated with an AI "suitability" score derived
/// from its best `Layout.Score` so the user can judge how well a room fits
/// before continuing.
class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({required this.floorPlan, super.key});

  final FloorPlanRecord floorPlan;

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
    required this.roomId,
    required this.name,
    required this.icon,
    required this.accent,
    required this.bounds,
    required this.suitability,
    required this.note,
    this.fromAnalysis = false,
    this.layoutsSupported = true,
  });

  /// True when this room came from the web pipeline's `DetectionJSON` (its id
  /// is a detector id like `room-2`, not a `Room` table key).
  final bool fromAnalysis;

  /// The web layout engine only produces layouts for living rooms.
  final bool layoutsSupported;

  /// The room id: a `Room.RoomID`, or a detector id when [fromAnalysis].
  final String roomId;
  final String name;
  final IconData icon;
  final _RoomAccent accent;

  /// Fractional bounds (0-1) within the floor plan diagram. The schema has
  /// no per-room position, so these are laid out in a simple grid rather
  /// than reflecting the plan's true geometry.
  final Rect bounds;

  /// Best `Layout.Score` found for this room (0-100), or 0 if no AI layout
  /// has been generated for it yet.
  final int suitability;
  final String note;

  Color colorIn(AppColors c) => accent.resolve(c);

  String get tag {
    if (suitability >= 90) return 'Excellent fit';
    if (suitability >= 75) return 'Great fit';
    if (suitability > 0) return 'Good fit';
    return 'Not yet scored';
  }
}

IconData _iconForRoomType(String roomType) {
  final type = roomType.toLowerCase();
  if (type.contains('living')) return Icons.weekend_outlined;
  if (type.contains('kitchen')) return Icons.kitchen_outlined;
  if (type.contains('bed')) return Icons.bed_outlined;
  if (type.contains('bath')) return Icons.bathtub_outlined;
  if (type.contains('dining')) return Icons.dining_outlined;
  if (type.contains('office') || type.contains('study')) {
    return Icons.desk_outlined;
  }
  if (type.contains('garage')) return Icons.garage_outlined;
  if (type.contains('hall')) return Icons.door_sliding_outlined;
  if (type.contains('balcony') || type.contains('patio')) {
    return Icons.balcony_outlined;
  }
  return Icons.meeting_room_outlined;
}

/// Lays out detected rooms in a simple grid, since the schema has no
/// per-room position within the source image.
Rect _boundsForIndex(int index, int total) {
  final columns = math.max(1, math.sqrt(total).ceil());
  final rows = (total / columns).ceil();
  final col = index % columns;
  final row = index ~/ columns;
  const gap = 0.03;
  final w = (1 - gap * (columns - 1)) / columns;
  final h = (1 - gap * (rows - 1)) / rows;
  return Rect.fromLTWH(col * (w + gap), row * (h + gap), w, h);
}

/// "4.2m × 3.1m · 13.0 m²", marking sizes the detector only estimated.
String _analysisRoomNote(AnalysisRoom room) {
  final w = room.widthM;
  final h = room.heightM;
  final area = room.areaM2;
  if (w == null || h == null || area == null) {
    return 'Size unknown — the plan has no printed scale';
  }
  return '${w.toStringAsFixed(1)}m × ${h.toStringAsFixed(1)}m · '
      '${area.toStringAsFixed(1)} m² (estimated)';
}

Future<List<_DetectedRoom>> _loadDetectedRooms(
  FloorPlanRecord floorPlan,
  AppColors c,
) async {
  final accents = _RoomAccent.values;

  // The web pipeline keeps detection results as JSON on the analysis row.
  final analysis = await FloorPlanRepository.instance.fetchAnalysis(
    floorPlan.floorPlanId,
  );
  final analysisRooms = analysis?.rooms ?? const <AnalysisRoom>[];
  if (analysisRooms.isNotEmpty) {
    final layoutSet = AnalysisLayoutSet.from(analysis?.layoutJson);
    return [
      for (final (i, room) in analysisRooms.indexed)
        _DetectedRoom(
          roomId: room.id,
          name: room.name,
          icon: _iconForRoomType(room.name),
          accent: accents[i % accents.length],
          bounds: room.bboxFraction ?? _boundsForIndex(i, analysisRooms.length),
          suitability:
              layoutSet != null &&
                  layoutSet.roomId == room.id &&
                  layoutSet.layouts.isNotEmpty
              ? layoutSet.layouts
                    .firstWhere(
                      (l) => l.type == layoutSet.bestType,
                      orElse: () => layoutSet.layouts.first,
                    )
                    .suitability
                    .round()
                    .clamp(0, 100)
              : 0,
          note: _analysisRoomNote(room),
          fromAnalysis: true,
          layoutsSupported: room.isLivingRoom,
        ),
    ];
  }

  // Older relational pipeline: rows in the `Room` / `Layout` tables.
  final rooms = await FloorPlanRepository.instance.fetchRooms(
    floorPlan.floorPlanId,
  );
  final result = <_DetectedRoom>[];
  for (final (i, room) in rooms.indexed) {
    final layouts = await FloorPlanRepository.instance.fetchLayouts(
      room.roomId,
    );
    final bestScore = layouts.isEmpty
        ? 0
        : layouts.first.score.round().clamp(0, 100);
    result.add(
      _DetectedRoom(
        roomId: room.roomId,
        name: room.roomType,
        icon: _iconForRoomType(room.roomType),
        accent: accents[i % accents.length],
        bounds: _boundsForIndex(i, rooms.length),
        suitability: bestScore,
        note:
            '${room.length.toStringAsFixed(1)}m × '
            '${room.width.toStringAsFixed(1)}m · '
            '${room.area.toStringAsFixed(1)} m² floor area',
      ),
    );
  }
  return result;
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  int _selected = 0;
  List<_DetectedRoom>? _rooms;
  bool _loadFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rooms == null) _load();
  }

  Future<void> _load() async {
    final colors = context.colors;
    setState(() => _loadFailed = false);
    try {
      final rooms = await _loadDetectedRooms(widget.floorPlan, colors);
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final wide = !context.screenSize.isMobile;
    final rooms = _rooms;

    Widget body;
    if (_loadFailed && rooms == null) {
      body = _LoadError(
        onRetry: _load,
        message: 'We could not load the detected rooms. Retry, or go back.',
      );
    } else if (rooms == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    } else if (rooms.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: c.textMuted, size: 46),
              const SizedBox(height: AppSpacing.lg),
              Text('No rooms detected yet', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check back shortly once analysis finishes.',
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
      );
    } else {
      final room = rooms[_selected.clamp(0, rooms.length - 1)];
      final diagram = _FloorPlanDiagram(
        rooms: rooms,
        selected: _selected,
        onSelect: (i) => setState(() => _selected = i),
      );
      final list = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detected rooms', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < rooms.length; i++) ...[
            _RoomCard(
              room: rooms[i],
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            ),
            if (i != rooms.length - 1) const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Design the ${room.name}',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => _openLayouts(context, room),
          ),
        ],
      );

      body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: diagram),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(flex: 4, child: list),
              ],
            )
          : Column(
              children: [
                diagram,
                const SizedBox(height: AppSpacing.xl),
                list,
              ],
            );
    }

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
                    rooms == null
                        ? 'Looking at your floor plan'
                        : 'We found ${rooms.length} room'
                              '${rooms.length == 1 ? '' : 's'}',
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
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLayouts(BuildContext context, _DetectedRoom room) {
    if (!room.layoutsSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Layouts are currently available for living rooms only. '
            'Pick the living room to continue.',
          ),
        ),
      );
      return;
    }
    // Analysis rooms are recorded when a layout is confirmed; the legacy
    // pipeline tracks the room as soon as it is chosen.
    if (!room.fromAnalysis) {
      unawaited(() async {
        try {
          await FloorPlanRepository.instance.selectRoomForAnalysis(
            floorPlanId: widget.floorPlan.floorPlanId,
            roomId: room.roomId,
          );
        } catch (_) {}
      }());
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayoutsScreen(
          room: room,
          floorPlanId: widget.floorPlan.floorPlanId,
        ),
      ),
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
              final local =
                  details.localPosition - const Offset(padding, padding);
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
