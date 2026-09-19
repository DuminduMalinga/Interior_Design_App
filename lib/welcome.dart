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
    final c = context.colors;
    final text = context.text;
    final wide = !context.screenSize.isMobile;

    final headline = _Headline(centered: !wide);
    final description = Text(
      'AI-powered room detection turns 2D architectural '
      'blueprints into photorealistic, interactive 3D '
      'environments in seconds.',
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: text.bodyMedium?.copyWith(color: c.textSecondary),
    );
    final hero = AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = math.sin(_floatController.value * math.pi) * 6;
        return Transform.translate(offset: Offset(0, -dy), child: child);
      },
      child: const _HeroCard(),
    );
    const stats = Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_outline_rounded,
            value: '98%',
            label: 'Boundary Accuracy',
            accent: _StatAccent.primary,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            icon: Icons.bolt_rounded,
            value: '15s',
            label: 'AI 3D Synthesis',
            accent: _StatAccent.secondary,
          ),
        ),
      ],
    );
    final note = Text(
      'No credit card required • Instant 3D CAD analysis',
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: text.labelSmall?.copyWith(color: c.textMuted),
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackground()),
          SafeArea(
            child: AppContentFrame(
              verticalPadding: AppSpacing.lg,
              child: Column(
                children: [
                  _WelcomeTopBar(onSignIn: () => _openAuth(context, true)),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: wide
                        ? Center(
                            child: SingleChildScrollView(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _StatusPill(),
                                        const SizedBox(height: AppSpacing.lg),
                                        headline,
                                        const SizedBox(height: AppSpacing.md),
                                        description,
                                        const SizedBox(height: AppSpacing.xl),
                                        Wrap(
                                          spacing: AppSpacing.md,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            AppButton(
                                              label: 'Get Started',
                                              icon: Icons.arrow_forward_rounded,
                                              iconAfterLabel: true,
                                              expanded: false,
                                              onPressed: () =>
                                                  _openAuth(context, false),
                                            ),
                                            AppButton(
                                              label: 'Sign In',
                                              variant:
                                                  AppButtonVariant.secondary,
                                              expanded: false,
                                              onPressed: () =>
                                                  _openAuth(context, true),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        note,
                                        const SizedBox(height: AppSpacing.xl),
                                        stats,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.huge),
                                  Expanded(child: hero),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                const _StatusPill(),
                                const SizedBox(height: AppSpacing.lg),
                                headline,
                                const SizedBox(height: AppSpacing.md),
                                description,
                                const SizedBox(height: AppSpacing.xl),
                                hero,
                                const SizedBox(height: AppSpacing.xl),
                                stats,
                              ],
                            ),
                          ),
                  ),
                  if (!wide) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      iconAfterLabel: true,
                      onPressed: () => _openAuth(context, false),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    note,
                  ],
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
    final c = context.colors;
    final text = context.text;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: c.brandGradient,
            borderRadius: AppRadius.smAll,
          ),
          child: SizedBox.square(
            dimension: 36,
            child: Icon(Icons.bolt_rounded, color: c.onPrimary, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 1),
        Text.rich(
          TextSpan(
            style: text.titleMedium,
            children: [
              const TextSpan(text: 'Planly '),
              TextSpan(
                text: 'AI',
                style: text.titleMedium?.copyWith(color: c.primary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppStatusChip(label: 'AI 3D', color: c.secondary),
        const Spacer(),
        TextButton(
          onPressed: onSignIn,
          style: TextButton.styleFrom(foregroundColor: c.textPrimary),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return const AppStatusChip(
      label: 'Next-Gen Spatial Intelligence',
      status: AppStatus.info,
      icon: Icons.hub_rounded,
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final style = context.responsive(
      mobile: context.text.headlineMedium,
      tablet: context.text.displayMedium,
      desktop: context.text.displayLarge,
    );
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text('Transform Floor Plans into', textAlign: align, style: style),
        ShaderMask(
          shaderCallback: (bounds) =>
              context.colors.brandGradient.createShader(bounds),
          // The text colour is replaced by the gradient; it only has to be
          // opaque for the mask to show through.
          child: Text(
            'Stunning 3D Spaces',
            textAlign: align,
            style: style?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

enum _StatAccent {
  primary,
  secondary;

  Color resolve(AppColors c) => switch (this) {
    primary => c.primary,
    secondary => c.secondary,
  };
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
  final _StatAccent accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final color = accent.resolve(c);

    return AppCard(
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: AppRadius.smAll,
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: text.titleMedium),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered panel framing the hero image, with floating status badges
/// pinned to its edges — the focal element of the screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AspectRatio(
      aspectRatio: 1.12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.backgroundElevated,
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: c.primary.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.xlAll,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1618219908412-a29a1bb7b86e'
                      '?auto=format&fit=crop&w=1000&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          CustomPaint(painter: _WelcomeHeroPainter(colors: c)),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ColoredBox(
                          color: c.backgroundElevated,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: c.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, c.scrim],
                          stops: const [.5, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _HeroBadge(
              icon: Icons.diamond_outlined,
              label: '3D Mesh: Detected',
            ),
          ),
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _HeroBadge(
              icon: Icons.auto_awesome_rounded,
              label: '60 FPS ISOMETRIC',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.backgroundElevated.withValues(alpha: 0.9),
        borderRadius: AppRadius.fullAll,
      ),
      child: AppStatusChip(label: label, icon: icon, color: c.accent),
    );
  }
}

class _WelcomeHeroPainter extends CustomPainter {
  const _WelcomeHeroPainter({required this.colors});

  final AppColors colors;

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
    final c = colors;

    final glow = Paint()
      ..color = c.primary.withValues(alpha: .18)
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
    _quad(canvas, floor, Paint()..color = c.surface);

    final grid = Paint()
      ..color = c.glassFill
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final t = i / 5 * w;
      canvas.drawLine(_project(t, 0, 0, size), _project(t, d, 0, size), grid);
      canvas.drawLine(_project(0, t, 0, size), _project(w, t, 0, size), grid);
    }

    final wallPaint = Paint()..color = c.primary.withValues(alpha: .08);
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
        ..shader = LinearGradient(
          colors: [c.primary, c.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(screenBounds)
        ..style = PaintingStyle.fill,
    );
    _quad(
      canvas,
      screenPts,
      Paint()
        ..color = c.accent.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final rug = [
      _project(w * .16, d * .16, .3, size),
      _project(w * .84, d * .16, .3, size),
      _project(w * .84, d * .84, .3, size),
      _project(w * .16, d * .84, .3, size),
    ];
    _quad(canvas, rug, Paint()..color = c.secondary.withValues(alpha: .10));

    _drawScanRing(canvas, size, 55, 42, 42);

    _box(canvas, size, 18, 22, 92, 62, 34, c.primary);
    _box(canvas, size, 118, 28, 178, 96, 46, c.secondary);
    _box(canvas, size, 28, 128, 100, 176, 26, c.accent);

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
      ..color = colors.accent.withValues(alpha: .5)
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
      ..color = colors.textPrimary.withValues(alpha: .5)
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
        ..color = colors.textPrimary.withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(bulb, 3, Paint()..color = colors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _WelcomeHeroPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-.7, -1),
            radius: 1.15,
            colors: [c.secondary.withValues(alpha: 0.18), Colors.transparent],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.9, .9),
              radius: 1.2,
              colors: [c.primary.withValues(alpha: 0.16), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
