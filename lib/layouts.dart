part of 'main.dart';

/// Shown after the user confirms a room on [RoomSelectionScreen].
///
/// Presents AI-generated furniture layout options for that room, each scored
/// against how well it suits the room the AI detected earlier. Phones get a
/// swipeable deck; wider screens get a grid so options can be compared.
// ignore_for_file: library_private_types_in_public_api
// `_DetectedRoom` is private to this app's single-library `part` setup
// (declared in room_selection.dart), not a leaked implementation detail.
class LayoutsScreen extends StatefulWidget {
  const LayoutsScreen({
    required this.room,
    required this.floorPlanId,
    super.key,
  });

  final _DetectedRoom room;

  /// The floor plan the room belongs to; the confirmed layout is saved
  /// against its analysis row.
  final String floorPlanId;

  @override
  State<LayoutsScreen> createState() => _LayoutsScreenState();
}

/// A generic title/tag "skin" cycled across real [LayoutRecord]s, since the
/// schema stores only a numeric score per layout, not a name or style tags.
const _layoutArchetypes = [
  ('Open & Airy', ['Minimalist', 'Natural light']),
  ('Warm Gathering', ['Scandinavian', 'Warm woods']),
  ('Cozy Corner', ['Modern', 'Soft textures']),
  ('Compact Efficient', ['Space-saving', 'Multi-use']),
];

class _LayoutOption {
  const _LayoutOption({
    required this.layoutId,
    required this.title,
    required this.tags,
    required this.matchScore,
    required this.variant,
    required this.furniture,
    this.analysis,
    this.isRecommended = false,
  });

  /// Set for layouts from the web pipeline's `LayoutJSON`; null for rows
  /// from the legacy `Layout` table.
  final AnalysisLayout? analysis;

  /// The engine's own pick (`bestLayout`) for this room.
  final bool isRecommended;

  /// Table `LayoutID`, or the engine layout `type` for [analysis] layouts.
  final String layoutId;
  final String title;
  final List<String> tags;
  final int matchScore;
  final int variant;
  final List<PlacedFurniture> furniture;
}

Future<List<_LayoutOption>> _loadLayoutOptions(
  _DetectedRoom room,
  String floorPlanId,
) async {
  if (room.fromAnalysis) {
    final analysis = await FloorPlanRepository.instance.fetchAnalysis(
      floorPlanId,
    );
    final set = AnalysisLayoutSet.from(analysis?.layoutJson);
    // The web stores layouts for one room at a time.
    if (set == null || set.roomId != room.roomId) return const [];
    final usable = set.layouts.where((l) => !l.hasError).toList();
    return [
      for (final (i, l) in usable.indexed)
        _LayoutOption(
          layoutId: l.type,
          title: l.title,
          tags: [
            '${l.furniture.length} pieces',
            l.valid ? 'Validated' : 'Needs review',
          ],
          matchScore: (l.suitability > 0 ? l.suitability : l.score)
              .round()
              .clamp(0, 100),
          variant: i,
          furniture: const [],
          analysis: l,
          isRecommended: set.bestType != null ? l.type == set.bestType : i == 0,
        ),
    ];
  }

  final roomId = room.roomId;
  final layouts = await FloorPlanRepository.instance.fetchLayouts(roomId);
  final options = <_LayoutOption>[];
  for (final (i, layout) in layouts.indexed) {
    final archetype = _layoutArchetypes[i % _layoutArchetypes.length];
    final furniture = await FloorPlanRepository.instance
        .fetchFurnitureForLayout(layout.layoutId);
    options.add(
      _LayoutOption(
        layoutId: layout.layoutId,
        title: archetype.$1,
        tags: archetype.$2,
        matchScore: layout.score.round().clamp(0, 100),
        variant: i,
        furniture: furniture,
      ),
    );
  }
  return options;
}

class _LayoutsScreenState extends State<LayoutsScreen> {
  late final PageController _pageController;
  int _page = 0;
  List<_LayoutOption>? _layouts;
  bool _loadFailed = false;
  String? _selectedLayoutId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .86);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final layouts = await _loadLayoutOptions(widget.room, widget.floorPlanId);
      final saved = await _loadSavedSelection(layouts);
      if (!mounted) return;
      setState(() {
        _layouts = layouts;
        _selectedLayoutId = saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  /// Returns the previously confirmed layout for this room, if any, so
  /// coming back to the screen keeps it selected. Failures here are not
  /// worth blocking the screen over.
  Future<String?> _loadSavedSelection(List<_LayoutOption> layouts) async {
    try {
      final analysis = await FloorPlanRepository.instance.fetchAnalysis(
        widget.floorPlanId,
      );
      final json = analysis?.selectedLayoutJson;
      if (json is Map) {
        // Legacy shape: {layoutId, roomId}. Web shape: the full layout
        // document, whose `layout.type` names it, for `SelectedRoomID`.
        final String? id;
        if (json['layoutId'] != null && json['roomId'] == widget.room.roomId) {
          id = json['layoutId'].toString();
        } else if (json['layout'] is Map &&
            analysis?.selectedRoomId == widget.room.roomId) {
          id = (json['layout'] as Map)['type']?.toString();
        } else {
          id = null;
        }
        if (id != null && layouts.any((l) => l.layoutId == id)) return id;
      }
    } catch (_) {}
    return null;
  }

  /// SRS UC8: confirm the choice (the top-scored layout is recommended, but
  /// any layout may be chosen instead), save it, then allow the 3D view.
  Future<void> _selectLayout(
    _LayoutOption layout, {
    required bool isBest,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Use "${layout.title}"?'),
        content: Text(
          isBest
              ? 'This is the highest-scoring layout for the '
                    '${widget.room.name} (${layout.matchScore}% match).'
              : 'This is not the highest-scoring layout, but you can '
                    'choose it instead of the recommendation '
                    '(${layout.matchScore}% match).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final analysis = layout.analysis;
      if (analysis != null) {
        await FloorPlanRepository.instance.saveSelectedAnalysisLayout(
          floorPlanId: widget.floorPlanId,
          roomId: widget.room.roomId,
          layout: analysis,
        );
      } else {
        await FloorPlanRepository.instance.saveSelectedLayout(
          floorPlanId: widget.floorPlanId,
          roomId: widget.room.roomId,
          layoutId: layout.layoutId,
          score: layout.matchScore.toDouble(),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your layout. Try again.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _selectedLayoutId = layout.layoutId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Layout saved.')));
    _open3D(layout);
  }

  void _open3D(_LayoutOption layout) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Room3DViewerScreen(room: widget.room, layout: layout),
      ),
    );
  }

  /// Builds a card wired to this screen's selection state. The list is
  /// ordered best-first, so index 0 is the recommended layout.
  Widget _cardFor(List<_LayoutOption> layouts, int index) {
    final layout = layouts[index];
    final isBest = layout.analysis != null ? layout.isRecommended : index == 0;
    return _LayoutCard(
      room: widget.room,
      layout: layout,
      isBest: isBest,
      isSelected: layout.layoutId == _selectedLayoutId,
      onSelect: () => _selectLayout(layout, isBest: isBest),
      onView3D: () => _open3D(layout),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final room = widget.room;
    final roomColor = room.colorIn(c);
    final isMobile = context.screenSize.isMobile;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(room.icon, color: roomColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Layouts for the ${room.name}',
                style: context.responsive(
                  mobile: text.headlineSmall,
                  tablet: text.headlineLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
            children: [
              const TextSpan(text: "Based on this room's "),
              TextSpan(
                text: '${room.suitability}% suitability',
                style: text.bodyMedium?.copyWith(
                  color: roomColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: isMobile
                    ? ', swipe to compare AI-scored layouts.'
                    : ', compare the AI-scored layouts below.',
              ),
            ],
          ),
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
        title: const Text('AI layouts'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: _layouts == null
              ? (_loadFailed ? _buildError(header) : _buildLoading(header))
              : _layouts!.isEmpty
              ? _buildEmpty(context, header)
              : isMobile
              ? _buildDeck(context, header, roomColor, _layouts!)
              : _buildGrid(context, header, _layouts!),
        ),
      ),
    );
  }

  Widget _buildLoading(Widget header) {
    return SingleChildScrollView(
      child: AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSpacing.huge),
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Widget header) {
    return SingleChildScrollView(
      child: AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            _LoadError(
              onRetry: _load,
              message: 'We could not load the layouts for this room.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, Widget header) {
    final c = context.colors;
    return SingleChildScrollView(
      child: AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSpacing.huge),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: c.textMuted,
                    size: 46,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('No AI layouts yet', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.room.fromAnalysis
                        ? 'Layouts for this room have not been generated yet. '
                              'Generate them from the web app, then refresh.'
                        : 'Layouts for this room are still being generated.',
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    expanded: false,
                    onPressed: () {
                      setState(() => _layouts = null);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeck(
    BuildContext context,
    Widget header,
    Color roomColor,
    List<_LayoutOption> layouts,
  ) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            0,
          ),
          child: header,
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: layouts.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final isActive = index == _page;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: isActive ? 0 : AppSpacing.lg,
                ),
                child: _cardFor(layouts, index),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < layouts.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? roomColor : c.border,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    Widget header,
    List<_LayoutOption> layouts,
  ) {
    return SingleChildScrollView(
      child: AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSpacing.xxl),
            AppResponsiveGrid(
              tabletColumns: 2,
              desktopColumns: 4,
              spacing: AppSpacing.xl,
              childAspectRatio: context.responsive(
                mobile: 1,
                tablet: 0.95,
                desktop: 0.78,
              ),
              children: [
                for (var i = 0; i < layouts.length; i++) _cardFor(layouts, i),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({
    required this.room,
    required this.layout,
    required this.isBest,
    required this.isSelected,
    required this.onSelect,
    required this.onView3D,
  });

  final _DetectedRoom room;
  final _LayoutOption layout;

  /// The highest-scoring layout, highlighted as the recommendation.
  final bool isBest;

  /// The layout the customer confirmed; only this one unlocks the 3D view.
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onView3D;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roomColor = room.colorIn(c);

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        border: isSelected || isBest
            ? Border.all(color: isSelected ? c.success : roomColor, width: 1.6)
            : null,
      ),
      child: AppCard(
        radius: AppRadius.xlAll,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: ColoredBox(
                        color: c.backgroundElevated,
                        child: CustomPaint(
                          painter: layout.analysis != null
                              ? _AnalysisPlanPainter(
                                  layout: layout.analysis!,
                                  wall: c.textPrimary.withValues(alpha: 0.35),
                                  door: c.accent,
                                  window: c.secondary,
                                  colorFor: (t) => _furnitureColor(t, c),
                                )
                              : _LayoutRenderPainter(
                                  accent: roomColor,
                                  wall: c.textPrimary.withValues(alpha: 0.3),
                                  variant: layout.variant,
                                ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.backgroundElevated.withValues(alpha: 0.85),
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: AppStatusChip(
                        label: '${layout.matchScore}% match',
                        status: _scoreStatus(layout.matchScore),
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                  ),
                  if (isSelected || isBest)
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.backgroundElevated.withValues(alpha: 0.85),
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: AppStatusChip(
                          label: isSelected ? 'Selected' : 'Recommended',
                          status: AppStatus.success,
                          icon: isSelected
                              ? Icons.check_circle_rounded
                              : Icons.star_rounded,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(layout.title, style: context.text.titleMedium),
                ),
                if (layout.analysis != null)
                  IconButton(
                    tooltip: 'Why this layout?',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    onPressed: () => _showLayoutDetails(context, layout),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm - 2,
              runSpacing: AppSpacing.sm - 2,
              children: [
                for (final tag in layout.tags) AppStatusChip(label: tag),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isSelected)
              OutlinedButton.icon(
                onPressed: onView3D,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: roomColor.withValues(alpha: 0.55)),
                  backgroundColor: roomColor.withValues(alpha: 0.10),
                ),
                icon: const Icon(Icons.view_in_ar_outlined, size: 18),
                label: const Text('View in 3D'),
              )
            else
              AppButton(
                label: isBest ? 'Select recommended' : 'Select this layout',
                icon: Icons.check_rounded,
                onPressed: onSelect,
              ),
          ],
        ),
      ),
    );
  }
}

/// A stylized top-down render of a furnished layout, distinguished per
/// [variant] so each swiped card reads as a distinct arrangement.
class _LayoutRenderPainter extends CustomPainter {
  const _LayoutRenderPainter({
    required this.accent,
    required this.wall,
    required this.variant,
  });

  final Color accent;
  final Color wall;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(
      room,
      Paint()
        ..color = wall
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final furnitureFill = Paint()..color = accent.withValues(alpha: .38);
    final furnitureStroke = Paint()
      ..color = accent.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pieces = switch (variant % 4) {
      0 => [
        Rect.fromLTWH(room.left + 10, room.top + 12, room.width * .42, 26),
        Rect.fromLTWH(
          room.left + room.width * .55,
          room.top + 14,
          room.width * .32,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + 12,
          room.bottom - room.height * .32,
          room.width * .5,
          room.height * .24,
        ),
      ],
      1 => [
        Rect.fromLTWH(
          room.left + room.width * .08,
          room.top + room.height * .1,
          room.width * .3,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + room.width * .45,
          room.top + room.height * .12,
          room.width * .45,
          room.height * .22,
        ),
        Rect.fromLTWH(
          room.left + room.width * .45,
          room.bottom - room.height * .35,
          room.width * .45,
          room.height * .25,
        ),
      ],
      2 => [
        Rect.fromLTWH(
          room.left + room.width * .1,
          room.top + room.height * .08,
          room.width * .8,
          room.height * .22,
        ),
        Rect.fromLTWH(
          room.left + room.width * .12,
          room.bottom - room.height * .34,
          room.width * .34,
          room.height * .26,
        ),
        Rect.fromLTWH(
          room.left + room.width * .55,
          room.bottom - room.height * .34,
          room.width * .34,
          room.height * .26,
        ),
      ],
      _ => [
        Rect.fromLTWH(
          room.left + room.width * .12,
          room.top + room.height * .14,
          room.width * .3,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + room.width * .5,
          room.top + room.height * .14,
          room.width * .38,
          room.height * .18,
        ),
        Rect.fromLTWH(
          room.left + room.width * .5,
          room.bottom - room.height * .3,
          room.width * .38,
          room.height * .2,
        ),
      ],
    };

    for (final piece in pieces) {
      final rrect = RRect.fromRectAndRadius(piece, const Radius.circular(6));
      canvas.drawRRect(rrect, furnitureFill);
      canvas.drawRRect(rrect, furnitureStroke);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        room.deflate(room.width * .18),
        const Radius.circular(10),
      ),
      Paint()
        ..color = accent.withValues(alpha: .10)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LayoutRenderPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.wall != wall ||
      oldDelegate.variant != variant;
}

Color _furnitureColor(String type, AppColors c) {
  switch (type) {
    case 'sofa':
    case 'loveseat':
    case 'l_sofa':
    case 'chair':
    case 'reading_chair':
    case 'desk_chair':
      return c.primary;
    case 'coffee_table':
    case 'side_table':
    case 'desk':
      return c.warning;
    case 'tv':
    case 'tv_console':
      return c.error;
    case 'bookshelf':
    case 'storage_cabinet':
      return c.secondary;
    default:
      return c.accent;
  }
}

/// A true-to-scale top-down plan of an engine layout: room outline with its
/// doors and windows, and every furniture piece at its real position.
/// Coordinates are millimetres with the origin at the bottom-left.
class _AnalysisPlanPainter extends CustomPainter {
  const _AnalysisPlanPainter({
    required this.layout,
    required this.wall,
    required this.door,
    required this.window,
    required this.colorFor,
  });

  final AnalysisLayout layout;
  final Color wall;
  final Color door;
  final Color window;
  final Color Function(String type) colorFor;

  @override
  void paint(Canvas canvas, Size size) {
    final roomW = layout.roomWidth;
    final roomL = layout.roomLength;
    if (roomW <= 0 || roomL <= 0) return;

    const pad = 12.0;
    final scale = math.min(
      (size.width - pad * 2) / roomW,
      (size.height - pad * 2) / roomL,
    );
    final ox = (size.width - roomW * scale) / 2;
    final oy = (size.height - roomL * scale) / 2;
    Offset pt(double x, double y) =>
        Offset(ox + x * scale, oy + (roomL - y) * scale);

    canvas.drawRect(
      Rect.fromPoints(pt(0, 0), pt(roomW, roomL)),
      Paint()
        ..color = wall
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    for (final o in layout.openings) {
      final (Offset a, Offset b) = switch (o.wall) {
        'south' => (pt(o.position, 0), pt(o.position + o.width, 0)),
        'north' => (pt(o.position, roomL), pt(o.position + o.width, roomL)),
        'west' => (pt(0, o.position), pt(0, o.position + o.width)),
        _ => (pt(roomW, o.position), pt(roomW, o.position + o.width)),
      };
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = o.isDoor ? door : window
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.butt,
      );
    }

    for (final f in layout.furniture) {
      final color = colorFor(f.type);
      final rect = Rect.fromPoints(pt(f.x0, f.y0), pt(f.x1, f.y1));
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: .38));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnalysisPlanPainter old) =>
      old.layout != layout ||
      old.wall != wall ||
      old.door != door ||
      old.window != window;
}

const _scoreComponentLabels = {
  'circulation': 'Circulation',
  'relationships': 'Relationships',
  'wall_alignment': 'Wall alignment',
  'window_access': 'Window access',
  'door_access': 'Door access',
  'symmetry': 'Symmetry',
  'usability': 'Usability',
  'completeness': 'Completeness',
  'layout_specific': 'Layout-specific',
};

/// Bottom sheet explaining an engine layout: why it was chosen, how it
/// scored, what it contains and any validation problems.
void _showLayoutDetails(BuildContext context, _LayoutOption option) {
  final a = option.analysis;
  if (a == null) return;
  final c = context.colors;
  final text = context.text;

  Widget section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    ),
  );

  Widget bullet(String s, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'â€¢  ',
          style: text.bodySmall?.copyWith(color: color ?? c.textMuted),
        ),
        Expanded(
          child: Text(
            s,
            style: text.bodySmall?.copyWith(color: color ?? c.textSecondary),
          ),
        ),
      ],
    ),
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Text(a.title, style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusChip(
                label: 'Score ${a.score.toStringAsFixed(1)}',
                status: AppStatus.info,
              ),
              AppStatusChip(
                label: '${option.matchScore}% suitable',
                status: _scoreStatus(option.matchScore),
              ),
              AppStatusChip(
                label: a.valid ? 'Validated' : 'Has issues',
                status: a.valid ? AppStatus.success : AppStatus.warning,
              ),
              if (option.isRecommended)
                const AppStatusChip(
                  label: 'Recommended',
                  status: AppStatus.success,
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          if (a.reasons.isNotEmpty)
            section('Why this layout', [
              for (final r in a.reasons.take(8)) bullet(r),
            ]),
          if (a.components.isNotEmpty)
            section('Score breakdown', [
              for (final e in a.components.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _scoreComponentLabels[e.key] ?? e.key,
                        style: text.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                      Text(
                        '${e.value >= 0 ? '+' : ''}${e.value.toStringAsFixed(1)}',
                        style: text.labelMedium?.copyWith(
                          color: e.value >= 0 ? c.success : c.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          if (a.furniture.isNotEmpty)
            section('Furniture (${a.furniture.length})', [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final f in a.furniture) AppStatusChip(label: f.label),
                ],
              ),
            ]),
          if (a.unplaced.isNotEmpty || a.notes.isNotEmpty)
            section('Notes', [
              for (final u in a.unplaced)
                bullet('Could not place required item: $u', color: c.warning),
              for (final n in a.notes) bullet(n),
            ]),
        ],
      ),
    ),
  );
}
