part of 'main.dart';

/// Shown when the user taps "View in 3D" on a [LayoutsScreen] card.
///
/// The isometric render fills nearly the whole screen; drag horizontally to
/// orbit, pinch to zoom, or use the floating gesture controls. UI chrome is
/// kept to a thin top bar and a floating bottom toolbar so the render stays
/// the focus.
// ignore_for_file: library_private_types_in_public_api
// `_DetectedRoom`/`_LayoutOption` are private to this app's single-library
// `part` setup, not leaked implementation details.
class Room3DViewerScreen extends StatefulWidget {
  const Room3DViewerScreen({
    required this.room,
    required this.layout,
    super.key,
  });

  final _DetectedRoom room;
  final _LayoutOption layout;

  @override
  State<Room3DViewerScreen> createState() => _Room3DViewerScreenState();
}

class _Room3DViewerScreenState extends State<Room3DViewerScreen> {
  static const _minYaw = -.6;
  static const _maxYaw = .6;
  static const _minZoom = .7;
  static const _maxZoom = 1.6;

  double _yaw = -.28;
  double _zoom = 1.0;
  double _yawStart = 0;
  double _zoomStart = 1;

  /// Marks the drawn room, so its picture can be saved or shared.
  final _pictureKey = GlobalKey();
  bool _exporting = false;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// The file name, without extension, for this room's picture.
  String get _fileStem => exportFileStem(
    widget.room.name,
    widget.layout.analysis?.type ?? widget.layout.title,
  );

  /// Runs a save or share of the room's picture, one at a time, telling the
  /// user if the picture can't be made or the action fails.
  Future<void> _withPicture(
    String failure,
    Future<void> Function(Uint8List png) action,
  ) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final png = await capturePng(
        _pictureKey,
        pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0),
      );
      if (png == null) {
        _say('The 3D view is not ready yet.');
        return;
      }
      await action(png);
    } catch (_) {
      _say(failure);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _export() =>
      _withPicture('Could not save the picture.', (png) async {
        final saved = await FilePicker.saveFile(
          fileName: '$_fileStem.png',
          bytes: png,
          mimeType: 'image/png',
          dialogTitle: 'Save picture',
        );
        if (saved != null) _say('Picture saved.');
      });

  Future<void> _share(Rect? origin) =>
      _withPicture('Could not share the picture.', (png) async {
        await SharePlus.instance.share(
          pictureShareParams(
            png: png,
            fileName: '$_fileStem.png',
            text: '${widget.room.name}: ${widget.layout.title}',
            origin: origin,
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final room = widget.room;
    final layout = widget.layout;
    final roomColor = room.colorIn(c);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) {
                  _yawStart = _yaw;
                  _zoomStart = _zoom;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _yaw = (_yawStart + details.focalPointDelta.dx * .0025)
                        .clamp(_minYaw, _maxYaw);
                    if (details.scale != 1.0) {
                      _zoom = (_zoomStart * details.scale).clamp(
                        _minZoom,
                        _maxZoom,
                      );
                    }
                  });
                },
                child: RepaintBoundary(
                  key: _pictureKey,
                  child: AppBackground(
                    child: CustomPaint(
                      painter: _IsoRoomPainter(
                        accent: roomColor,
                        floor: c.surface,
                        grid: c.glassFill,
                        variant: layout.variant,
                        yaw: _yaw,
                        zoom: _zoom,
                        placedFurniture: layout.furniture,
                        analysis: layout.analysis,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.md,
              child: _GlassIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              left: 0,
              right: 0,
              child: Center(
                child: _TitlePill(room: room, layout: layout),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GestureRail(
                  onRotateLeft: () => setState(
                    () => _yaw = (_yaw - .16).clamp(_minYaw, _maxYaw),
                  ),
                  onRotateRight: () => setState(
                    () => _yaw = (_yaw + .16).clamp(_minYaw, _maxYaw),
                  ),
                  onZoomIn: () => setState(
                    () => _zoom = (_zoom + .12).clamp(_minZoom, _maxZoom),
                  ),
                  onZoomOut: () => setState(
                    () => _zoom = (_zoom - .12).clamp(_minZoom, _maxZoom),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
              // Keeps the toolbar a sensible width on tablet and desktop.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _ViewerToolbar(
                    accent: roomColor,
                    busy: _exporting,
                    onExport: _export,
                    onShare: _share,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.backgroundElevated.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: c.glassBorder),
          ),
          child: Icon(icon, size: 20, color: c.textPrimary),
        ),
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.room, required this.layout});

  final _DetectedRoom room;
  final _LayoutOption layout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.backgroundElevated.withValues(alpha: 0.6),
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: c.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(room.icon, size: 14, color: room.colorIn(c)),
          const SizedBox(width: AppSpacing.sm - 2),
          Text(
            '${layout.title} · ${room.name}',
            style: context.text.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Floating rotate / zoom affordances alongside direct drag & pinch on the
/// render itself.
class _GestureRail extends StatelessWidget {
  const _GestureRail({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassIconButton(icon: Icons.zoom_in_rounded, onTap: onZoomIn),
        const SizedBox(height: AppSpacing.md),
        _GlassIconButton(icon: Icons.zoom_out_rounded, onTap: onZoomOut),
        const SizedBox(height: AppSpacing.xl),
        _GlassIconButton(icon: Icons.rotate_left_rounded, onTap: onRotateLeft),
        const SizedBox(height: AppSpacing.md),
        _GlassIconButton(
          icon: Icons.rotate_right_rounded,
          onTap: onRotateRight,
        ),
      ],
    );
  }
}

class _ViewerToolbar extends StatelessWidget {
  const _ViewerToolbar({
    required this.accent,
    required this.busy,
    required this.onExport,
    required this.onShare,
  });

  final Color accent;

  /// A picture is being made, so Export and Share wait.
  final bool busy;
  final VoidCallback onExport;

  /// Gets the area of the Share button, which iPad anchors its sheet to.
  final void Function(Rect? origin) onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.backgroundElevated.withValues(alpha: 0.9),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: c.glassBorder),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .18),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarAction(
            icon: Icons.download_rounded,
            label: 'Export',
            busy: busy,
            onTap: onExport,
          ),
          Builder(
            builder: (context) => _ToolbarAction(
              icon: Icons.share_rounded,
              label: 'Share',
              busy: busy,
              onTap: () {
                final box = context.findRenderObject();
                onShare(
                  box is RenderBox && box.hasSize
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null,
                );
              },
            ),
          ),
          _ToolbarAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            accent: accent,
            onTap: () => _notify(context, 'Edit'),
          ),
        ],
      ),
    );
  }

  void _notify(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action coming soon.')));
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  /// Dims the action and ignores taps while something else is running.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.colors.textPrimary;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: AppRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm - 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: busy ? color.withValues(alpha: 0.4) : color,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: busy ? color.withValues(alpha: 0.4) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a rotatable, zoomable isometric room with abstract furniture
/// blocks, projected with a true 3D rotation about the vertical axis so
/// dragging genuinely orbits the render rather than faking a skew.
class _IsoRoomPainter extends CustomPainter {
  const _IsoRoomPainter({
    required this.accent,
    required this.floor,
    required this.grid,
    required this.variant,
    required this.yaw,
    required this.zoom,
    this.placedFurniture = const [],
    this.analysis,
  });

  /// A layout from the web pipeline. When set, the room takes its real
  /// proportions and the furniture its real positions and heights.
  final AnalysisLayout? analysis;

  final Color accent;
  final Color floor;
  final Color grid;
  final int variant;
  final double yaw;
  final double zoom;

  /// Real `FurnitureLayout`/`Furniture` rows for this layout, when the
  /// backend has placed any. Falls back to a stylized procedural layout
  /// (see [_furniture]) when empty, since not every layout has furniture
  /// placements yet.
  final List<PlacedFurniture> placedFurniture;

  static const _roomH = 120.0;

  double get _aspect {
    final a = analysis;
    return a != null && a.roomLength > 0 && a.roomWidth > 0
        ? a.roomWidth / a.roomLength
        : 1.0;
  }

  /// The longer side of the room always spans 200 painter units.
  double get _roomW => _aspect >= 1 ? 200.0 : 200.0 * _aspect;
  double get _roomD => _aspect >= 1 ? 200.0 / _aspect : 200.0;

  /// Engine furniture (mm) mapped into painter units with a single uniform
  /// scale so pieces keep their true proportions.
  List<_FurnitureBox> _analysisFurnitureBoxes() {
    final a = analysis;
    if (a == null || a.roomWidth <= 0) return const [];
    final k = _roomW / a.roomWidth;
    return [
      for (final f in a.furniture)
        _FurnitureBox(
          (f.x0 * k).clamp(0.0, _roomW),
          (f.y0 * k).clamp(0.0, _roomD),
          (f.x1 * k).clamp(0.0, _roomW),
          (f.y1 * k).clamp(0.0, _roomD),
          (f.height * k).clamp(6.0, 90.0),
        ),
    ];
  }

  /// Maps real furniture placements (room-relative position/size in meters)
  /// onto the painter's 0-200 unit room space.
  List<_FurnitureBox> _realFurnitureBoxes() {
    const metersToUnits = 40.0; // ~5m room maps across the 200-unit floor.
    return [
      for (final item in placedFurniture)
        if (item.placement.positionX != null &&
            item.placement.positionY != null)
          _FurnitureBox(
            (item.placement.positionX! * metersToUnits).clamp(0, _roomW - 4),
            (item.placement.positionY! * metersToUnits).clamp(0, _roomD - 4),
            (item.placement.positionX! * metersToUnits +
                    (item.furniture.width ?? 0.6) * metersToUnits)
                .clamp(4, _roomW),
            (item.placement.positionY! * metersToUnits +
                    (item.furniture.length ?? 0.6) * metersToUnits)
                .clamp(4, _roomD),
            36,
          ),
    ];
  }

  Offset _project(double x, double y, double z, Size size) {
    final rx = x * math.cos(yaw) - y * math.sin(yaw);
    final ry = x * math.sin(yaw) + y * math.cos(yaw);
    final scale = (size.shortestSide / 300) * zoom;
    final sx = (rx - ry) * math.cos(math.pi / 6);
    final sy = (rx + ry) * math.sin(math.pi / 6) - z;
    return Offset(size.width / 2 + sx * scale, size.height * .6 + sy * scale);
  }

  void _quad(Canvas canvas, List<Offset> pts, Paint paint) {
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = analysis;
    if (a != null && a.furniture.isNotEmpty && a.roomWidth > 0) {
      _paintLayout(canvas, size, a);
      return;
    }
    final floorQuad = [
      _project(0, 0, 0, size),
      _project(_roomW, 0, 0, size),
      _project(_roomW, _roomD, 0, size),
      _project(0, _roomD, 0, size),
    ];
    _quad(canvas, floorQuad, Paint()..color = floor);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final t = i / 5 * _roomW;
      canvas.drawLine(
        _project(t, 0, 0, size),
        _project(t, _roomD, 0, size),
        gridPaint,
      );
      canvas.drawLine(
        _project(0, t, 0, size),
        _project(_roomW, t, 0, size),
        gridPaint,
      );
    }

    final wallPaint = Paint()..color = accent.withValues(alpha: .07);
    _quad(canvas, [
      _project(0, 0, 0, size),
      _project(0, _roomD, 0, size),
      _project(0, _roomD, _roomH, size),
      _project(0, 0, _roomH, size),
    ], wallPaint);
    _quad(canvas, [
      _project(0, 0, 0, size),
      _project(_roomW, 0, 0, size),
      _project(_roomW, 0, _roomH, size),
      _project(0, 0, _roomH, size),
    ], wallPaint);

    final fromAnalysis = _analysisFurnitureBoxes();
    final real = fromAnalysis.isNotEmpty ? fromAnalysis : _realFurnitureBoxes();
    final pieces = real.isNotEmpty
        ? real
        : _furniture[variant % _furniture.length];
    final sorted = [...pieces]
      ..sort((a, b) => (a.x1 + a.y1).compareTo(b.x1 + b.y1));
    for (final p in sorted) {
      _drawBox(canvas, size, p);
    }

    final rugPaint = Paint()..color = accent.withValues(alpha: .10);
    final rug = [
      _project(_roomW * .18, _roomD * .18, .3, size),
      _project(_roomW * .82, _roomD * .18, .3, size),
      _project(_roomW * .82, _roomD * .82, .3, size),
      _project(_roomW * .18, _roomD * .82, .3, size),
    ];
    _quad(canvas, rug, rugPaint);
  }

  // ── A layout from the engines: the real room, openings and furniture ──

  void _paintLayout(Canvas canvas, Size size, AnalysisLayout a) {
    final k = _roomW / a.roomWidth; // painter units per mm
    final wallH = (a.roomHeight * k).clamp(60.0, 140.0);
    final bathroom = _isBathroom(a.furniture);
    final warm = bathroom
        ? Color.lerp(floor, const Color(0xFFC9CDD0), .6)!
        : Color.lerp(floor, _Finish.oak, .28)!;

    // the floor, less the notch of an L-shaped room
    var floorPath = Path()
      ..addPolygon([
        _project(0, 0, 0, size),
        _project(_roomW, 0, 0, size),
        _project(_roomW, _roomD, 0, size),
        _project(0, _roomD, 0, size),
      ], true);
    for (final c in a.cutouts) {
      floorPath = Path.combine(
        PathOperation.difference,
        floorPath,
        Path()..addPolygon([
          _project(c[0] * k, _roomD - c[3] * k, 0, size),
          _project(c[2] * k, _roomD - c[3] * k, 0, size),
          _project(c[2] * k, _roomD - c[1] * k, 0, size),
          _project(c[0] * k, _roomD - c[1] * k, 0, size),
        ], true),
      );
    }
    canvas.drawPath(floorPath, Paint()..color = warm);
    final plank = Paint()
      ..color = grid
      ..strokeWidth = 1;
    // bathroom floors are square tiles, 600 mm
    final tile = 600 * k;
    if (bathroom) {
      for (var x = tile; x < _roomW; x += tile) {
        canvas.drawLine(
          _project(x, 0, 0, size),
          _project(x, _roomD, 0, size),
          plank,
        );
      }
    }
    final planks = bathroom ? (_roomD / tile).floor() : (_roomD / 14).floor();
    for (var i = 1; i < planks; i++) {
      final y = i * (bathroom ? tile : 14.0);
      canvas.drawLine(
        _project(0, y, 0, size),
        _project(_roomW, y, 0, size),
        plank,
      );
    }

    // the two far walls (north and west), with their doors and windows
    final wall = Color.lerp(accent, Colors.white, .86)!.withValues(alpha: .55);
    _wall(canvas, size, a, k, wallH, 'north', wall);
    _wall(canvas, size, a, k, wallH, 'west', wall);
    // the two near walls show only as a skirting line and their openings
    _nearEdge(canvas, size, a, k, 'south');
    _nearEdge(canvas, size, a, k, 'east');

    final solids = _buildFurniture(
      a.furniture,
      k: k,
      roomD: _roomD,
      roomW: a.roomWidth,
      roomL: a.roomLength,
    );
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    double depth(_Solid s) =>
        (s.cx * cosY - s.cy * sinY) + (s.cx * sinY + s.cy * cosY);
    final flat = [
      for (final s in solids)
        if (s.flat) s,
    ];
    final upright =
        [
          for (final s in solids)
            if (!s.flat && s.color.a >= 1) s,
        ]..sort((x, y) {
          final byDepth = depth(x).compareTo(depth(y));
          return byDepth != 0 ? byDepth : x.z0.compareTo(y.z0);
        });
    // glass is drawn last, over what stands behind it
    final glass = [
      for (final s in solids)
        if (s.color.a < 1) s,
    ];
    for (final s in [...flat, ...upright, ...glass]) {
      _drawSolid(canvas, size, s);
    }
  }

  /// Wall position (mm along the wall) to painter units.
  double _along(String wall, double pos, double k) =>
      wall == 'north' || wall == 'south'
      ? pos * k
      : _roomD - pos * k; // east/west positions run south to north

  void _wall(
    Canvas canvas,
    Size size,
    AnalysisLayout a,
    double k,
    double wallH,
    String side,
    Color color,
  ) {
    final north = side == 'north';
    Offset at(double t, double z) =>
        north ? _project(t, 0, z, size) : _project(0, t, z, size);
    final length = north ? _roomW : _roomD;
    _quad(canvas, [
      at(0, 0),
      at(length, 0),
      at(length, wallH),
      at(0, wallH),
    ], Paint()..color = color);
    canvas.drawLine(
      at(0, 4),
      at(length, 4),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 2,
    );
    for (final o in a.openings) {
      if (o.wall != side || o.inset >= 1) continue;
      final p0 = _along(side, o.position, k);
      final p1 = _along(side, o.position + o.width, k);
      final t0 = math.min(p0, p1);
      final t1 = math.max(p0, p1);
      final z0 = o.isDoor ? 0.0 : (o.sillHeight ?? 900) * k;
      final z1 = o.isDoor ? 2100 * k : z0 + (o.height ?? 1200) * k;
      _quad(
        canvas,
        [at(t0, z0), at(t1, z0), at(t1, z1), at(t0, z1)],
        Paint()
          ..color = o.isDoor
              ? _Finish.walnut.withValues(alpha: .85)
              : _Finish.glass.withValues(alpha: .75),
      );
      if (!o.isDoor) {
        final line = Paint()
          ..color = Colors.white.withValues(alpha: .9)
          ..strokeWidth = 1.5;
        final mid = (t0 + t1) / 2;
        canvas.drawLine(at(mid, z0), at(mid, z1), line);
        canvas.drawLine(at(t0, (z0 + z1) / 2), at(t1, (z0 + z1) / 2), line);
      }
    }
  }

  void _nearEdge(
    Canvas canvas,
    Size size,
    AnalysisLayout a,
    double k,
    String side,
  ) {
    final south = side == 'south';
    Offset at(double t) =>
        south ? _project(t, _roomD, 0, size) : _project(_roomW, t, 0, size);
    final length = south ? _roomW : _roomD;
    canvas.drawLine(
      at(0),
      at(length),
      Paint()
        ..color = accent.withValues(alpha: .35)
        ..strokeWidth = 2,
    );
    for (final o in a.openings) {
      if (o.wall != side || o.inset >= 1) continue;
      final p0 = _along(side, o.position, k);
      final p1 = _along(side, o.position + o.width, k);
      canvas.drawLine(
        at(math.min(p0, p1)),
        at(math.max(p0, p1)),
        Paint()
          ..color = o.isDoor ? _Finish.walnut : _Finish.glass
          ..strokeWidth = 4,
      );
    }
  }

  void _drawSolid(Canvas canvas, Size size, _Solid s) {
    final alpha = s.color.a;
    final top = _tone(s.color, .12).withValues(alpha: alpha);
    final yShade = _tone(s.color, -.1).withValues(alpha: alpha);
    final xShade = _tone(s.color, -.26).withValues(alpha: alpha);
    if (s.round) {
      const n = 18;
      final rx = (s.x1 - s.x0) / 2;
      final ry = (s.y1 - s.y0) / 2;
      Offset ring(int i, double z) {
        final t = 2 * math.pi * i / n;
        return _project(
          s.cx + rx * math.cos(t),
          s.cy + ry * math.sin(t),
          z,
          size,
        );
      }

      for (var i = 0; i < n; i++) {
        final mid = 2 * math.pi * (i + .5) / n;
        final nx =
            math.cos(mid) * math.cos(yaw) - math.sin(mid) * math.sin(yaw);
        final ny =
            math.cos(mid) * math.sin(yaw) + math.sin(mid) * math.cos(yaw);
        final facing = nx + ny;
        if (facing <= 0) continue;
        _quad(
          canvas,
          [ring(i, s.z0), ring(i + 1, s.z0), ring(i + 1, s.z1), ring(i, s.z1)],
          Paint()
            ..color = Color.lerp(xShade, yShade, (facing / 1.41).clamp(0, 1))!,
        );
      }
      _quad(canvas, [
        for (var i = 0; i < n; i++) ring(i, s.z1),
      ], Paint()..color = top);
      return;
    }
    _quad(canvas, [
      _project(s.x0, s.y0, s.z1, size),
      _project(s.x1, s.y0, s.z1, size),
      _project(s.x1, s.y1, s.z1, size),
      _project(s.x0, s.y1, s.z1, size),
    ], Paint()..color = top);
    _quad(canvas, [
      _project(s.x0, s.y1, s.z0, size),
      _project(s.x1, s.y1, s.z0, size),
      _project(s.x1, s.y1, s.z1, size),
      _project(s.x0, s.y1, s.z1, size),
    ], Paint()..color = yShade);
    _quad(canvas, [
      _project(s.x1, s.y0, s.z0, size),
      _project(s.x1, s.y1, s.z0, size),
      _project(s.x1, s.y1, s.z1, size),
      _project(s.x1, s.y0, s.z1, size),
    ], Paint()..color = xShade);
  }

  void _drawBox(Canvas canvas, Size size, _FurnitureBox p) {
    final top = [
      _project(p.x0, p.y0, p.h, size),
      _project(p.x1, p.y0, p.h, size),
      _project(p.x1, p.y1, p.h, size),
      _project(p.x0, p.y1, p.h, size),
    ];
    _quad(canvas, top, Paint()..color = accent.withValues(alpha: .55));

    final yFace = [
      _project(p.x0, p.y1, 0, size),
      _project(p.x1, p.y1, 0, size),
      _project(p.x1, p.y1, p.h, size),
      _project(p.x0, p.y1, p.h, size),
    ];
    _quad(canvas, yFace, Paint()..color = accent.withValues(alpha: .75));

    final xFace = [
      _project(p.x1, p.y0, 0, size),
      _project(p.x1, p.y1, 0, size),
      _project(p.x1, p.y1, p.h, size),
      _project(p.x1, p.y0, p.h, size),
    ];
    _quad(canvas, xFace, Paint()..color = accent.withValues(alpha: .9));
  }

  static final _furniture = [
    // Open & Airy
    [
      _FurnitureBox(20, 20, 90, 60, 34),
      _FurnitureBox(120, 30, 175, 100, 46),
      _FurnitureBox(30, 130, 100, 175, 28),
    ],
    // Warm Gathering
    [
      _FurnitureBox(15, 100, 70, 180, 40),
      _FurnitureBox(100, 20, 180, 65, 42),
      _FurnitureBox(100, 110, 180, 175, 44),
    ],
    // Cozy Corner
    [
      _FurnitureBox(20, 15, 175, 55, 30),
      _FurnitureBox(20, 120, 80, 180, 46),
      _FurnitureBox(120, 120, 180, 180, 46),
    ],
    // Compact Efficient
    [
      _FurnitureBox(25, 25, 85, 80, 42),
      _FurnitureBox(105, 25, 175, 65, 36),
      _FurnitureBox(105, 115, 175, 175, 40),
    ],
  ];

  @override
  bool shouldRepaint(covariant _IsoRoomPainter oldDelegate) =>
      oldDelegate.yaw != yaw ||
      oldDelegate.zoom != zoom ||
      oldDelegate.accent != accent ||
      oldDelegate.floor != floor ||
      oldDelegate.grid != grid ||
      oldDelegate.variant != variant ||
      oldDelegate.placedFurniture != placedFurniture ||
      oldDelegate.analysis != analysis;
}

class _FurnitureBox {
  const _FurnitureBox(this.x0, this.y0, this.x1, this.y1, this.h);

  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final double h;
}
