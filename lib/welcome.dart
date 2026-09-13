part of 'main.dart';

/// Cool cyan-blue used across the hero illustration's status badges.
const _heroCyan = Color(0xFF5EC8F2);

/// The app's landing screen — first thing a new user sees before signing up
/// or jumping into the dashboard.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: Column(
                children: [
                  _WelcomeTopBar(onSignIn: () => _openAuth(context, true)),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const _StatusPill(),
                          const SizedBox(height: 18),
                          const _Headline(),
                          const SizedBox(height: 11),
                          const Text(
                            'AI-powered room detection turns 2D architectural '
                            'blueprints into photorealistic, interactive 3D '
                            'environments in seconds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final dy =
                                  math.sin(_floatController.value * math.pi) *
                                  6;
                              return Transform.translate(
                                offset: Offset(0, -dy),
                                child: child,
                              );
                            },
                            child: _HeroCard(pulse: _floatController),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.check_circle_outline_rounded,
                                  value: '98%',
                                  label: 'Boundary Accuracy',
                                  accent: _blue,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.bolt_rounded,
                                  value: '15s',
                                  label: 'AI 3D Synthesis',
                                  accent: _violet,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_blue, _violet],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withValues(alpha: .45),
                            blurRadius: 34,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _openAuth(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No credit card required • Instant 3D CAD analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAuth(BuildContext context, bool signIn) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(startInSignIn: signIn),
      ),
    );
  }
}

/// Brand mark + wordmark on the left, a "Sign In" shortcut on the right.
class _WelcomeTopBar extends StatelessWidget {
  const _WelcomeTopBar({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 9),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Planly ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _violet.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _violet.withValues(alpha: .4)),
          ),
          child: const Text(
            'AI 3D',
            style: TextStyle(
              color: Color(0xFFC9B8FF),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSignIn,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withValues(alpha: .32)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded, color: Color(0xFF83B9FF), size: 13),
            SizedBox(width: 6),
            Text(
              'Next-Gen Spatial Intelligence',
              style: TextStyle(
                color: Color(0xFFB9D5FF),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Transform Floor Plans into',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_blue, _violet],
          ).createShader(bounds),
          child: const Text(
            'Stunning 3D Spaces',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered panel framing the isometric hero illustration, with floating
/// status badges pinned to its edges — the focal element of the screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1220),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blue.withValues(alpha: .22)),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: .12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WelcomeHeroPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) {
                      final t = (math.sin(pulse.value * math.pi * 2) + 1) / 2;
                      return Positioned(
                        left: 26,
                        top: 40,
                        child: _PulseDot(intensity: t),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 8,
            left: 8,
            child: _HeroBadge(
              icon: Icons.diamond_outlined,
              label: '3D Mesh: Detected',
              color: _heroCyan,
            ),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: _HeroBadge(
              icon: Icons.auto_awesome_rounded,
              label: '60 FPS ISOMETRIC',
              color: _heroCyan,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -14,
            child: Center(
              child: _HeroBadge(
                icon: Icons.layers_outlined,
                label: 'Neural Spatial Engine',
                color: _heroCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4ADE80);
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .35 + intensity * .35),
            blurRadius: 6 + intensity * 8,
            spreadRadius: 1 + intensity * 2,
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE60D111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeroPainter extends CustomPainter {
  static const _yaw = -.42;

  Offset _project(double x, double y, double z, Size size) {
    final rx = x * math.cos(_yaw) - y * math.sin(_yaw);
    final ry = x * math.sin(_yaw) + y * math.cos(_yaw);
    final scale = size.shortestSide / 260;
    final sx = (rx - ry) * math.cos(math.pi / 6);
    final sy = (rx + ry) * math.sin(math.pi / 6) - z;
    return Offset(size.width / 2 + sx * scale, size.height * .58 + sy * scale);
  }

  void _quad(Canvas canvas, List<Offset> pts, Paint paint) {
    canvas.drawPath(Path()..addPolygon(pts, true), paint);
  }

  void _box(
    Canvas canvas,
    Size size,
    double x0,
    double y0,
    double x1,
    double y1,
    double h,
    Color accent,
  ) {
    _quad(canvas, [
      _project(x0, y0, h, size),
      _project(x1, y0, h, size),
      _project(x1, y1, h, size),
      _project(x0, y1, h, size),
    ], Paint()..color = accent.withValues(alpha: .55));
    _quad(canvas, [
      _project(x0, y1, 0, size),
      _project(x1, y1, 0, size),
      _project(x1, y1, h, size),
      _project(x0, y1, h, size),
    ], Paint()..color = accent.withValues(alpha: .78));
    _quad(canvas, [
      _project(x1, y0, 0, size),
      _project(x1, y1, 0, size),
      _project(x1, y1, h, size),
      _project(x1, y0, h, size),
    ], Paint()..color = accent.withValues(alpha: .92));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const w = 200.0, d = 200.0, h = 110.0;

    final glow = Paint()
      ..color = _blue.withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(
      Offset(size.width / 2, size.height * .62),
      size.shortestSide * .42,
      glow,
    );

    final floor = [
      _project(0, 0, 0, size),
      _project(w, 0, 0, size),
      _project(w, d, 0, size),
      _project(0, d, 0, size),
    ];
    _quad(canvas, floor, Paint()..color = const Color(0xFF141B29));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final t = i / 5 * w;
      canvas.drawLine(_project(t, 0, 0, size), _project(t, d, 0, size), grid);
      canvas.drawLine(_project(0, t, 0, size), _project(w, t, 0, size), grid);
    }

    final wallPaint = Paint()..color = _blue.withValues(alpha: .08);
    _quad(canvas, [
      _project(0, 0, 0, size),
      _project(0, d, 0, size),
      _project(0, d, h, size),
      _project(0, 0, h, size),
    ], wallPaint);
    _quad(canvas, [
      _project(0, 0, 0, size),
      _project(w, 0, 0, size),
      _project(w, 0, h, size),
      _project(0, 0, h, size),
    ], wallPaint);

    // A slim screen panel leaning against the right-back wall.
    final screenPts = [
      _project(120, 0, 46, size),
      _project(168, 0, 46, size),
      _project(168, 0, 96, size),
      _project(120, 0, 96, size),
    ];
    final screenBounds = Rect.fromPoints(
      screenPts.reduce(
        (a, b) => Offset(math.min(a.dx, b.dx), math.min(a.dy, b.dy)),
      ),
      screenPts.reduce(
        (a, b) => Offset(math.max(a.dx, b.dx), math.max(a.dy, b.dy)),
      ),
    );
    _quad(
      canvas,
      screenPts,
      Paint()
        ..shader = const LinearGradient(
          colors: [_blue, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(screenBounds)
        ..style = PaintingStyle.fill,
    );
    _quad(
      canvas,
      screenPts,
      Paint()
        ..color = _heroCyan.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final rug = [
      _project(w * .16, d * .16, .3, size),
      _project(w * .84, d * .16, .3, size),
      _project(w * .84, d * .84, .3, size),
      _project(w * .16, d * .84, .3, size),
    ];
    _quad(canvas, rug, Paint()..color = _violet.withValues(alpha: .10));

    _drawScanRing(canvas, size, 55, 42, 42);

    _box(canvas, size, 18, 22, 92, 62, 34, _blue);
    _box(canvas, size, 118, 28, 178, 96, 46, _violet);
    _box(canvas, size, 28, 128, 100, 176, 26, const Color(0xFF35C5B5));

    _drawFloorLamp(canvas, size, 172, 148);
  }

  /// A dashed circular "AI scan" ring on the floor beneath a piece of
  /// furniture, echoing the radar-style detail in the reference art.
  void _drawScanRing(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double radius,
  ) {
    final paint = Paint()
      ..color = _heroCyan.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    const segments = 48;
    Offset? previous;
    for (var i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;
      final point = _project(
        cx + math.cos(angle) * radius,
        cy + math.sin(angle) * radius,
        .5,
        size,
      );
      if (previous != null && i.isEven) {
        canvas.drawLine(previous, point, paint);
      }
      previous = point;
    }
  }

  /// A slim arched floor lamp, drawn directly in projected space.
  void _drawFloorLamp(Canvas canvas, Size size, double x, double y) {
    final base = _project(x, y, 0, size);
    final bulb = _project(x - 26, y - 8, 68, size);
    final control = _project(x - 4, y - 4, 62, size);
    final stem = Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(control.dx, control.dy, bulb.dx, bulb.dy),
      stem,
    );
    canvas.drawCircle(
      bulb,
      6,
      Paint()
        ..color = Colors.white.withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(bulb, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WelcomeHeroPainter oldDelegate) => false;
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-.7, -1),
          radius: 1.15,
          colors: [_violet.withValues(alpha: .18), Colors.transparent],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.9, .9),
            radius: 1.2,
            colors: [_blue.withValues(alpha: .16), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
