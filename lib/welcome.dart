part of 'main.dart';

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
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const _AiPill(),
                          const SizedBox(height: 22),
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final dy =
                                  math.sin(_floatController.value * math.pi) *
                                  7;
                              return Transform.translate(
                                offset: Offset(0, -dy),
                                child: child,
                              );
                            },
                            child: const _WelcomeHero(),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Transform Floor Plans into\nStunning 3D Spaces',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              height: 1.16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Our AI detects every room in your floor plan and '
                            'turns it into a fully furnished, photoreal 3D '
                            'design in seconds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.track_changes_rounded,
                                  value: '98%',
                                  label: 'Accuracy',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.bolt_rounded,
                                  value: '15 sec',
                                  label: 'Avg. render time',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
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
                        onPressed: () => _getStarted(context),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

/// Isometric 3D room illustration used as the welcome screen's hero visual.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: CustomPaint(painter: _WelcomeHeroPainter(), size: Size.infinite),
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

    final rug = [
      _project(w * .16, d * .16, .3, size),
      _project(w * .84, d * .16, .3, size),
      _project(w * .84, d * .84, .3, size),
      _project(w * .16, d * .84, .3, size),
    ];
    _quad(canvas, rug, Paint()..color = _violet.withValues(alpha: .10));

    _box(canvas, size, 18, 22, 92, 62, 34, _blue);
    _box(canvas, size, 118, 28, 178, 96, 46, _violet);
    _box(canvas, size, 28, 128, 100, 176, 26, const Color(0xFF35C5B5));
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
