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
  const Room3DViewerScreen({required this.room, required this.layout, super.key});

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

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final layout = widget.layout;
    return Scaffold(
      backgroundColor: _background,
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
                child: ColoredBox(
                  color: _background,
                  child: CustomPaint(
                    painter: _IsoRoomPainter(
                      accent: room.color,
                      variant: layout.variant,
                      yaw: _yaw,
                      zoom: _zoom,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 12,
              child: _GlassIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(
                child: _TitlePill(room: room, layout: layout),
              ),
            ),
            Positioned(
              right: 12,
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
              left: 16,
              right: 16,
              bottom: 12,
              child: _ViewerToolbar(accent: room.color),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x990D111D),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x990D111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(room.icon, size: 13, color: room.color),
          const SizedBox(width: 6),
          Text(
            '${layout.title} · ${room.name}',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
        const SizedBox(height: 10),
        _GlassIconButton(icon: Icons.zoom_out_rounded, onTap: onZoomOut),
        const SizedBox(height: 22),
        _GlassIconButton(
          icon: Icons.rotate_left_rounded,
          onTap: onRotateLeft,
        ),
        const SizedBox(height: 10),
        _GlassIconButton(
          icon: Icons.rotate_right_rounded,
          onTap: onRotateRight,
        ),
      ],
    );
  }
}

class _ViewerToolbar extends StatelessWidget {
  const _ViewerToolbar({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE60D111D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
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
            icon: Icons.ios_share_rounded,
            label: 'Export',
            onTap: () => _notify(context, 'Export'),
          ),
          _ToolbarAction(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () => _notify(context, 'Share'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text('$action coming soon.'),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
    required this.variant,
    required this.yaw,
    required this.zoom,
  });

  final Color accent;
  final int variant;
  final double yaw;
  final double zoom;

  static const _roomW = 200.0;
  static const _roomD = 200.0;
  static const _roomH = 120.0;

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
    final floor = [
      _project(0, 0, 0, size),
      _project(_roomW, 0, 0, size),
      _project(_roomW, _roomD, 0, size),
      _project(0, _roomD, 0, size),
    ];
    _quad(canvas, floor, Paint()..color = const Color(0xFF141B29));

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .05)
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

    final pieces = _furniture[variant % _furniture.length];
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
      oldDelegate.variant != variant;
}

class _FurnitureBox {
  const _FurnitureBox(this.x0, this.y0, this.x1, this.y1, this.h);

  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final double h;
}
