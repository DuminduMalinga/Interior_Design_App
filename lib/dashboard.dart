part of 'main.dart';

const _navItems = [
  (Icons.home_rounded, 'Home'),
  (Icons.grid_view_rounded, 'Projects'),
  (Icons.cloud_upload_outlined, 'Upload'),
  (Icons.person_outline_rounded, 'Profile'),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  // Every tab but Home opens its own screen; Home just stays put.
  void _select(int index) {
    switch (index) {
      case 1:
        _open(const ProjectsScreen());
      case 2:
        _open(const UploadScreen());
      case 3:
        _open(const ProfileScreen());
      default:
        setState(() => _selectedTab = index);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;
    final content = _DashboardContent(
      size: size,
      onSeeAll: () => _select(1),
      onAvatarTap: () => _open(const ProfileScreen()),
      onAdminTap: () => _open(const AdminAccountsScreen()),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
        child: SafeArea(
          child: size.isMobile
              ? content
              : Row(
                  children: [
                    _SideNav(
                      extended: size.isDesktop,
                      selectedIndex: _selectedTab,
                      onSelected: _select,
                    ),
                    Expanded(child: content),
                  ],
                ),
        ),
      ),
      floatingActionButton: size.isMobile
          ? FloatingActionButton(
              heroTag: 'new-upload',
              onPressed: () => _open(const UploadScreen()),
              tooltip: 'New upload',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: size.isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: _select,
              items: [
                for (final (icon, label) in _navItems)
                  BottomNavigationBarItem(icon: Icon(icon), label: label),
              ],
            )
          : null,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.size,
    required this.onSeeAll,
    required this.onAvatarTap,
    required this.onAdminTap,
  });

  final ScreenSize size;
  final VoidCallback onSeeAll;
  final VoidCallback onAvatarTap;
  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    const hero = _HeroBanner();

    return SingleChildScrollView(
      child: AppContentFrame(
        // Keeps the last row clear of the mobile floating action button.
        bottomInset: size.isMobile ? 72 : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAvatarTap: onAvatarTap, onAdminTap: onAdminTap),
            const SizedBox(height: AppSpacing.xxl),
            if (size.isDesktop)
              const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: hero),
                    SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 2, child: _TipCard(vertical: true)),
                  ],
                ),
              )
            else
              hero,
            const SizedBox(height: AppSpacing.xxl),
            AppSectionHeader(
              title: 'Recent Projects',
              actionLabel: 'See all',
              onAction: onSeeAll,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ProjectGrid(),
            if (!size.isDesktop) ...[
              const SizedBox(height: AppSpacing.xxl),
              const _TipCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.extended,
    required this.selectedIndex,
    required this.onSelected,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.backgroundElevated,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: NavigationRail(
        extended: extended,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoMark(size: 40),
              if (extended) ...[
                const SizedBox(width: AppSpacing.md),
                Text('LiviSpace', style: context.text.titleLarge),
              ],
            ],
          ),
        ),
        destinations: [
          for (final (icon, label) in _navItems)
            NavigationRailDestination(icon: Icon(icon), label: Text(label)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAvatarTap, required this.onAdminTap});

  final VoidCallback onAvatarTap;
  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    IconButton actionButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(color: c.border),
          ),
        ),
        icon: Icon(icon, size: 22, color: c.textPrimary),
      );
    }

    return Row(
      children: [
        Tooltip(
          message: 'Profile',
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.brandGradient,
                border: Border.all(color: c.glassBorder, width: 1.5),
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Text(
                    'JM',
                    style: text.labelLarge?.copyWith(color: c.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, Jamie',
                style: context.responsive(
                  mobile: text.titleMedium,
                  tablet: text.titleLarge,
                ),
              ),
              Text(
                'Ready to design something great?',
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
        actionButton(
          icon: Icons.admin_panel_settings_outlined,
          tooltip: 'Manage accounts',
          onPressed: onAdminTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        actionButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: () {},
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final isMobile = context.screenSize.isMobile;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surfaceElevated, c.backgroundElevated, c.background],
        ),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
        boxShadow: AppShadows.medium,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlAll,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.secondary.withValues(alpha: 0.35),
                      c.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox.square(dimension: 260),
              ),
            ),
            Positioned(
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
              child: Transform.rotate(
                angle: -0.08,
                child: SizedBox(
                  width: isMobile ? 84 : 140,
                  height: isMobile ? 100 : 168,
                  child: CustomPaint(
                    painter: _PlanPainter(
                      accent: c.accent,
                      lineColor: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: isMobile ? 176 : 232),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  isMobile ? 116 : 200,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AiPill(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Turn sketches into smart floor plans.',
                      style: context.responsive(
                        mobile: text.titleLarge,
                        tablet: text.headlineMedium,
                        desktop: text.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Upload an image and let AI do the work.',
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Upload floor plan',
                        icon: Icons.cloud_upload_outlined,
                        expanded: false,
                        onPressed: () {},
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared with the room selection screen, which is why it lives at library
/// level instead of inside the hero.
class _AiPill extends StatelessWidget {
  const _AiPill();

  @override
  Widget build(BuildContext context) {
    return const AppStatusChip(
      label: 'Powered by AI',
      status: AppStatus.info,
      icon: Icons.auto_awesome_rounded,
    );
  }
}

class _Project {
  const _Project(this.title, this.date, this.accent, this.imageUrl);

  final String title;
  final String date;
  final Color accent;
  final String imageUrl;
}

/// Mock project data shared by the dashboard's "Recent Projects" preview and
/// the full [ProjectsScreen] list. There is no backend yet, so this stands in
/// for a user's saved projects.
List<_Project> _mockProjects(AppColors c) => [
  _Project(
    'Loft Apartment',
    'Just now',
    c.primary,
    'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Coastal Retreat',
    'Yesterday',
    c.accent,
    'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Studio Workspace',
    'Aug 24, 2024',
    c.secondary,
    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Family Residence',
    'Aug 18, 2024',
    c.warning,
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Downtown Penthouse',
    'Aug 12, 2024',
    c.primary,
    'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Garden Bungalow',
    'Aug 5, 2024',
    c.accent,
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Minimalist Studio',
    'Jul 29, 2024',
    c.secondary,
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=85',
  ),
  _Project(
    'Rooftop Lounge',
    'Jul 21, 2024',
    c.warning,
    'https://images.unsplash.com/photo-1615873968403-89e068629265?auto=format&fit=crop&w=900&q=85',
  ),
];

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid();

  @override
  Widget build(BuildContext context) {
    // The dashboard only teases recent work; "See all" opens the full list.
    final projects = _mockProjects(context.colors).take(4).toList();

    return AppResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      childAspectRatio: context.responsive(
        mobile: 0.88,
        tablet: 1.0,
        desktop: 1.1,
      ),
      children: [
        for (final (index, project) in projects.indexed)
          _ProjectCard(project: project, planIndex: index),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.planIndex});

  final _Project project;
  final int planIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {},
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              project.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: c.surfaceElevated,
                child: CustomPaint(
                  painter: _PlanPainter(
                    accent: project.accent,
                    lineColor: c.textPrimary,
                    variant: planIndex,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, c.scrim],
                  stops: const [0.4, 1],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: AppCard(
                glass: true,
                radius: AppRadius.smAll,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: c.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  project.date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall?.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({this.vertical = false});

  /// Stack the icon above the text, for a tall side-panel placement.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = Icon(
      Icons.lightbulb_outline_rounded,
      color: c.warning,
      size: vertical ? 28 : 22,
    );
    final message = Text(
      'Pro tip: Clear, top-down photos give the most accurate AI results.',
      style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: c.primary.withValues(alpha: 0.2),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon, const SizedBox(height: AppSpacing.md), message],
            )
          : Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: message),
              ],
            ),
    );
  }
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter({
    required this.accent,
    required this.lineColor,
    this.variant = 0,
  });

  final Color accent;
  final Color lineColor;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = lineColor.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final detail = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = accent.withValues(alpha: 0.10);
    const inset = 10.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRect(rect, stroke);

    Rect room(double l, double t, double w, double h) => Rect.fromLTWH(
      rect.left + rect.width * l,
      rect.top + rect.height * t,
      rect.width * w,
      rect.height * h,
    );

    final rooms = variant.isEven
        ? [
            room(0, 0, .48, .45),
            room(.52, 0, .48, .45),
            room(0, .5, .48, .5),
            room(.52, .5, .48, .5),
          ]
        : [
            room(0, 0, .58, .42),
            room(.62, 0, .38, .42),
            room(0, .47, .35, .53),
            room(.39, .47, .61, .53),
          ];
    for (var i = 0; i < rooms.length; i++) {
      canvas.drawRect(rooms[i], i == variant ? fill : stroke);
      if (i == 0) {
        canvas.drawCircle(rooms[i].center, size.width * .08, detail);
      }
    }
    canvas.drawLine(
      Offset(rect.left + rect.width * .2, rect.bottom),
      Offset(rect.left + rect.width * .3, rect.bottom - 9),
      detail,
    );
  }

  @override
  bool shouldRepaint(covariant _PlanPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.variant != variant;
}
