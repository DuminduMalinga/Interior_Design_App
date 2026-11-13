part of 'main.dart';

/// Shown after [ProcessingScreen] finishes analyzing the uploaded floor plan.
///
/// Presents the AI-detected rooms (the `Room` rows a backend pipeline wrote
/// for [floorPlan]) as an interactive top-down diagram plus a list of
/// tappable cards, each annotated with an AI "suitability" score derived
/// from its best `Layout.Score` so the user can judge how well a room fits
/// before continuing.
class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({required this.floorPlan, super.key})
    : _preview = null;

  /// Shows [data] as if it had just loaded, without the database.
  const RoomSelectionScreen._preview({
    required this.floorPlan,
    required _RoomSelectionData data,
  }) : _preview = data;

  final _RoomSelectionData? _preview;

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
    this.outline,
    this.confidence,
    this.sizeNote,
  });

  /// The room's outline on the plan image as fractions (0-1), when the
  /// detection recorded where it is.
  final List<Offset>? outline;

  /// How sure the detector is it found a room here (0-1).
  final double? confidence;

  /// Where the size on [note] came from, e.g. "from the plan's printed area".
  final String? sizeNote;

  /// True when this room came from the web pipeline's `DetectionJSON` (its id
  /// is a detector id like `room-2`, not a `Room` table key).
  final bool fromAnalysis;

  /// Whether a layout engine is wired up for this kind of room yet.
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

  /// Which layout engine this room gets, from its name.
  RoomKind? get kind => RoomKind.fromName(name);

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

/// What the room-selection screen shows: the rooms, and the plan they sit on.
class _RoomSelectionData {
  const _RoomSelectionData({
    required this.rooms,
    this.planUrl,
    this.aspectRatio = 4 / 3,
    this.counts = const {},
  });

  final List<_DetectedRoom> rooms;

  /// A short-lived link to the uploaded plan image, when it could be made.
  final String? planUrl;
  final double aspectRatio;
  final Map<String, int> counts;

  /// Whether every room has a position, so the plan can be drawn truthfully;
  /// otherwise the screen falls back to its schematic diagram.
  bool get canOverlay =>
      rooms.isNotEmpty && rooms.every((r) => r.outline != null);
}

Future<_RoomSelectionData> _loadDetectedRooms(
  FloorPlanRecord floorPlan,
  AppColors c,
) async {
  final accents = _RoomAccent.values;

  // The web pipeline keeps detection results as JSON on the analysis row.
  final analysis = await FloorPlanRepository.instance.fetchAnalysis(
    floorPlan.floorPlanId,
  );
  final plan = analysis?.plan ?? AnalysisPlan.empty;
  final analysisRooms = plan.rooms;
  if (analysisRooms.isNotEmpty) {
    final layoutSet = AnalysisLayoutSet.from(analysis?.layoutJson);
    String? planUrl;
    try {
      planUrl = await FloorPlanRepository.instance.signedUrlFor(
        floorPlan.imagePath,
      );
    } catch (_) {
      // the outlines still show without the picture
    }
    final rooms = [
      for (final (i, room) in analysisRooms.indexed)
        _DetectedRoom(
          roomId: room.id,
          name: room.name,
          icon: _iconForRoomType(room.name),
          accent: accents[i % accents.length],
          bounds: room.bboxFraction ?? _boundsForIndex(i, analysisRooms.length),
          outline: room.outline,
          confidence: room.confidence,
          sizeNote: plan.sizeOf(room)?.note,
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
          note: _sizeLine(plan.sizeOf(room)),
          fromAnalysis: true,
          layoutsSupported: RoomKind.fromName(room.name)?.isSupported ?? false,
        ),
    ];
    return _RoomSelectionData(
      rooms: rooms,
      planUrl: planUrl,
      aspectRatio: plan.aspectRatio,
      counts: plan.counts,
    );
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
  return _RoomSelectionData(rooms: result);
}

/// "4.20 × 3.10 m · 13.0 m²", or a plain note when the plan gave no size.
String _sizeLine(RoomSize? size) =>
    size == null ? 'Size unknown' : '${size.dims} · ${size.area}';

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  /// Index into the loaded rooms of the chosen one; none until one that can
  /// be furnished exists.
  int? _selected;
  _RoomSelectionData? _data;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final preview = widget._preview;
    if (preview != null) {
      _data = preview;
      final first = preview.rooms.indexWhere((r) => r.layoutsSupported);
      _selected = first == -1 ? null : first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) _load();
  }

  Future<void> _load() async {
    final colors = context.colors;
    setState(() => _loadFailed = false);
    try {
      final data = await _loadDetectedRooms(widget.floorPlan, colors);
      if (!mounted) return;
      setState(() {
        _data = data;
        // start on the first room that can be furnished, if there is one
        final first = data.rooms.indexWhere((r) => r.layoutsSupported);
        _selected = first == -1 ? null : first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final wide = !context.screenSize.isMobile;
    final data = _data;
    final rooms = data?.rooms;
    final furnishable = rooms?.where((r) => r.layoutsSupported).length ?? 0;

    Widget body;
    Widget? cta;
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
      final selected = _selected;
      final room = selected == null ? null : rooms[selected];
      // The real plan with each room's outline on it; rooms the detection
      // gave no position for fall back to the schematic diagram.
      final Widget diagram = data!.canOverlay
          ? PlanOverlay(
              rooms: [
                for (final r in rooms)
                  PlanOverlayRoom(
                    name: r.name,
                    outline: r.outline!,
                    selectable: r.layoutsSupported,
                  ),
              ],
              aspectRatio: data.aspectRatio,
              imageUrl: data.planUrl,
              counts: data.counts,
              selected: selected,
              onSelect: (i) => setState(() => _selected = i),
              onBlocked: (i) =>
                  _say("${rooms[i].name} can't be furnished yet."),
            )
          : _FloorPlanDiagram(
              rooms: rooms,
              selected: selected ?? -1,
              onSelect: (i) {
                if (rooms[i].layoutsSupported) {
                  setState(() => _selected = i);
                } else {
                  _say("${rooms[i].name} can't be furnished yet.");
                }
              },
            );

      final ready = [
        for (var i = 0; i < rooms.length; i++)
          if (rooms[i].layoutsSupported) i,
      ];
      final blocked = [
        for (var i = 0; i < rooms.length; i++)
          if (!rooms[i].layoutsSupported) i,
      ];

      final list = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room != null) ...[
            _SelectedRoomCard(room: room),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Rooms you can furnish', style: text.titleSmall),
          const SizedBox(height: AppSpacing.md - 2),
          if (ready.isEmpty)
            Text(
              'None of the rooms in this plan can be furnished yet.',
              style: text.bodySmall?.copyWith(color: c.textMuted),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                const gap = AppSpacing.sm;
                final cols = box.maxWidth >= 420 ? 4 : 3;
                final w = (box.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final i in ready)
                      SizedBox(
                        width: w,
                        child: _RoomTile(
                          room: rooms[i],
                          selected: i == selected,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (blocked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Can't furnish yet",
                  style: text.labelMedium?.copyWith(color: c.textMuted),
                ),
                for (final i in blocked)
                  _BlockedRoomChip(
                    label: rooms[i].name,
                    selected: i == selected,
                    onTap: () => setState(() => _selected = i),
                  ),
              ],
            ),
          ],
        ],
      );

      cta = room == null
          ? const AppButton(label: 'Choose a room', onPressed: null)
          : room.layoutsSupported
          ? AppButton(
              label: 'See layouts for ${room.name.toLowerCase()}',
              icon: Icons.arrow_forward_rounded,
              iconAfterLabel: true,
              onPressed: () => _openLayouts(context, room),
            )
          : AppButton(
              label: 'No layouts for ${room.name.toLowerCase()} yet',
              variant: AppButtonVariant.secondary,
              onPressed: null,
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

    final header = Row(
      children: [
        AppRoundButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Detected rooms', style: text.titleMedium),
              Text(
                rooms == null
                    ? 'Looking at your floor plan'
                    : '${rooms.length} room${rooms.length == 1 ? '' : 's'} · '
                          '$furnishable we can furnish',
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 44),
      ],
    );

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: AppContentFrame(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.lg),
                        body,
                      ],
                    ),
                  ),
                ),
              ),
              if (cta != null)
                AppContentFrame(verticalPadding: AppSpacing.md, child: cta),
            ],
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
            'Layouts are not available for this room yet. Pick a living '
            'room, bedroom, kitchen, bathroom or dining area to continue.',
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

/// The picked room: name, tag, how sure the detector was and how well it
/// suits a redesign.
class _SelectedRoomCard extends StatelessWidget {
  const _SelectedRoomCard({required this.room});

  final _DetectedRoom room;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final ok = room.layoutsSupported;
    final conf = room.confidence;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: text.titleLarge),
                    if (room.sizeNote != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Size ${room.sizeNote}',
                        style: text.bodySmall?.copyWith(color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ok ? c.primary.withValues(alpha: 0.16) : c.border,
                  borderRadius: AppRadius.fullAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md - 2,
                    vertical: 5,
                  ),
                  child: Text(
                    ok ? 'Can furnish' : 'Not yet',
                    style: text.labelSmall?.copyWith(
                      color: ok ? c.accent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniFact(
                  label: 'Detector confidence',
                  child: Text(
                    conf == null ? '–' : '${(conf * 100).round()}%',
                    style: text.titleSmall,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MiniFact(
                  label: 'Suitability',
                  child: Row(
                    children: [
                      Text(
                        ok && room.suitability > 0
                            ? '${room.suitability}'
                            : '–',
                        style: text.titleSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.fullAll,
                          child: LinearProgressIndicator(
                            value: ok ? room.suitability / 100 : 0,
                            minHeight: 6,
                            backgroundColor: c.border,
                            valueColor: AlwaysStoppedAnimation(c.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (room.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              room.note,
              style: text.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A pickable room in the "you can furnish" grid; the picked one is gold.
class _RoomTile extends StatelessWidget {
  const _RoomTile({
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
    final fg = selected ? c.onPrimary : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primary : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: selected ? c.primary : c.border),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.sm + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: fg),
                ),
                Text(
                  room.suitability > 0 ? 'Score ${room.suitability}' : 'Ready',
                  style: text.labelSmall?.copyWith(
                    color: fg.withValues(alpha: .8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed-outline chip for a room that has no layouts yet.
class _BlockedRoomChip extends StatelessWidget {
  const _BlockedRoomChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.surfaceElevated : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.textMuted : c.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm - 1,
          ),
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The room selection screen with these rooms, without the database.
/// Each is (name, size, detector confidence, score, where the size came
/// from); a score of 0 marks a room that can't be furnished yet.
@visibleForTesting
Widget roomSelectionPreviewForTest(
  List<(String, String, double, int, String)> rooms,
) {
  final accents = _RoomAccent.values;
  return RoomSelectionScreen._preview(
    floorPlan: FloorPlanRecord(
      floorPlanId: 'preview',
      userId: 'preview',
      imagePath: '',
      status: 'Detected',
      uploadDateTime: DateTime(2026, 11, 1),
    ),
    data: _RoomSelectionData(
      rooms: [
        for (final (i, r) in rooms.indexed)
          _DetectedRoom(
            roomId: 'room-$i',
            name: r.$1,
            icon: _iconForRoomType(r.$1),
            accent: accents[i % accents.length],
            bounds: _boundsForIndex(i, rooms.length),
            suitability: r.$4,
            note: r.$2,
            confidence: r.$3,
            sizeNote: r.$5,
            fromAnalysis: true,
            layoutsSupported: RoomKind.fromName(r.$1)?.isSupported ?? false,
          ),
      ],
    ),
  );
}
