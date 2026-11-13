part of 'main.dart';

/// The app's landing screen — first thing a new user sees before signing up
/// or jumping into the dashboard.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.loadStats});

  /// Where the live totals come from; the database unless a test says
  /// otherwise.
  final Future<SiteStats?> Function()? loadStats;

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

    const headline = _Headline(centered: false);
    final description = Text(
      'Upload a floor plan, let AI read your rooms, and choose a layout '
      'made for the way you live.',
      style: text.bodyLarge?.copyWith(color: c.textSecondary),
    );
    final hero = AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = math.sin(_floatController.value * math.pi) * 6;
        return Transform.translate(offset: Offset(0, -dy), child: child);
      },
      child: const _HeroCard(),
    );
    final stats = _WelcomeStats(load: widget.loadStats);
    final signInRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: text.bodyMedium?.copyWith(color: c.textMuted),
        ),
        GestureDetector(
          onTap: () => _openAuth(context, true),
          child: Text(
            'Sign in',
            style: text.bodyMedium?.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: AppContentFrame(
            verticalPadding: AppSpacing.lg,
            child: Column(
              children: [
                _WelcomeTopBar(onSignIn: () => _openAuth(context, true)),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      variant: AppButtonVariant.secondary,
                                      expanded: false,
                                      onPressed: () => _openAuth(context, true),
                                    ),
                                  ],
                                ),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Phone: a full-bleed room photo that fades into the page, the headline
    // low on the screen, and one big call to action.
    final heroHeight = MediaQuery.sizeOf(context).height * .62;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: const _HeroImage(),
          ),
          Positioned(
            top: heroHeight * .45,
            left: 0,
            right: 0,
            height: heroHeight * .55 + 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.background.withValues(alpha: 0),
                    c.background.withValues(alpha: .85),
                    c.background,
                  ],
                  stops: const [0, .6, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _WelcomeTopBar(onSignIn: () => _openAuth(context, true)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.huge * 3),
                              headline,
                              const SizedBox(height: AppSpacing.md + 2),
                              description,
                              const SizedBox(height: AppSpacing.xl),
                              stats,
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PillCta(
                    label: 'Get Started',
                    onPressed: () => _openAuth(context, false),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  signInRow,
                  const SizedBox(height: AppSpacing.lg),
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
            color: c.background.withValues(alpha: .55),
            borderRadius: AppRadius.smAll,
            border: Border.all(color: c.textPrimary.withValues(alpha: .25)),
          ),
          child: const SizedBox.square(
            dimension: 40,
            child: Center(child: AppLogoMark(size: 24)),
          ),
        ),
        const SizedBox(width: AppSpacing.md - 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LiviSpace', style: text.titleMedium),
            Text(
              'BETTER LIVING',
              style: text.labelSmall?.copyWith(
                color: c.textSecondary,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (!context.screenSize.isMobile)
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(foregroundColor: c.textPrimary),
            child: const Text('Sign In'),
          ),
      ],
    );
  }
}

/// The landing screen's call to action: a gold pill whose arrow sits in a
/// dark circle at its right edge.
class _PillCta extends StatelessWidget {
  const _PillCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.primary,
        borderRadius: AppRadius.fullAll,
        child: InkWell(
          borderRadius: AppRadius.fullAll,
          onTap: onPressed,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.text.titleMedium?.copyWith(
                        color: c.onPrimary,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: c.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final style = context.responsive(
      mobile: context.text.displayMedium,
      tablet: context.text.displayMedium,
      desktop: context.text.displayLarge,
    );
    return Text(
      'Design spaces\nfor better living',
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: style,
    );
  }
}

/// The four totals under the headline, as on the web's landing page. The
/// counts are live; until they load, or if they can't, they show a dash.
class _WelcomeStats extends StatefulWidget {
  const _WelcomeStats({this.load});

  final Future<SiteStats?> Function()? load;

  @override
  State<_WelcomeStats> createState() => _WelcomeStatsState();
}

class _WelcomeStatsState extends State<_WelcomeStats> {
  SiteStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    SiteStats? stats;
    try {
      stats = await (widget.load ?? SiteStatsRepository.instance.fetch)();
    } catch (_) {
      stats = null;
    }
    if (!mounted || stats == null) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    Widget pair(_StatTile a, _StatTile b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: b),
      ],
    );

    return Column(
      children: [
        pair(
          _StatTile(
            icon: Icons.group_outlined,
            value: formatCount(stats?.users),
            label: 'Registered users',
            accent: _StatAccent.primary,
          ),
          const _StatTile(
            icon: Icons.bolt_rounded,
            value: '< 2 min',
            label: 'Processing time',
            accent: _StatAccent.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        pair(
          _StatTile(
            icon: Icons.view_in_ar_rounded,
            value: formatCount(stats?.layouts),
            label: 'Layouts generated',
            accent: _StatAccent.secondary,
          ),
          _StatTile(
            icon: Icons.cloud_upload_outlined,
            value: formatCount(stats?.floorPlans),
            label: 'Floor plans uploaded',
            accent: _StatAccent.primary,
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

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      radius: AppRadius.mdAll,
      child: Row(
        children: [
          Icon(icon, color: c.primary, size: 18),
          const SizedBox(width: AppSpacing.md - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
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
                border: Border.all(color: c.border),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.xlAll,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _HeroImage(),
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
              label: 'Rooms detected',
            ),
          ),
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _HeroBadge(
              icon: Icons.auto_awesome_rounded,
              label: 'Live 3D',
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -14,
            child: Center(
              child: _HeroBadge(
                icon: Icons.layers_outlined,
                label: 'AI layouts',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The room photo, with the isometric drawing as its offline fallback.
class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Image.network(
      'https://images.unsplash.com/photo-1618219908412-a29a1bb7b86e'
      '?auto=format&fit=crop&w=1000&q=80',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: c.surface,
        child: CustomPaint(painter: _WelcomeHeroPainter(colors: c)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: c.surface,
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
