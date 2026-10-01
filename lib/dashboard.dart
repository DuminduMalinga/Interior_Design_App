part of 'main.dart';

const _navItems = [
  (Icons.home_rounded, 'Home'),
  (Icons.grid_view_rounded, 'Projects'),
  (Icons.cloud_upload_outlined, 'Upload'),
  (Icons.person_outline_rounded, 'Profile'),
];

/// Switches to one of the four tab screens.
///
/// Uses [Navigator.pushReplacement] rather than [Navigator.push]: pushing
/// would stack the new tab's screen on top of the old one, and since only
/// the *current* screen draws the nav bar/rail, the whole shell would
/// visibly disappear while its (identical-looking) replacement slid in.
/// Replacing keeps exactly one tab screen on the stack at a time, so the
/// bar never hides.
void _switchTab(BuildContext context, int index) {
  final screen = switch (index) {
    1 => const ProjectsScreen(),
    2 => const UploadScreen(),
    3 => const ProfileScreen(),
    _ => const DashboardScreen(),
  };
  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Shared chrome for the four tab screens: a bottom nav on mobile or a side
/// rail on wider screens. Every tab screen renders through this so the nav
/// stays visually identical — and present — no matter which tab is active.
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.selectedIndex,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  final int selectedIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;

    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
        child: SafeArea(
          child: size.isMobile
              ? body
              : Row(
                  children: [
                    _SideNav(
                      extended: size.isDesktop,
                      selectedIndex: selectedIndex,
                      onSelected: (index) => _switchTab(context, index),
                    ),
                    Expanded(child: body),
                  ],
                ),
        ),
      ),
      // Wide screens show the same destinations in the side rail instead.
      floatingActionButton: size.isMobile ? floatingActionButton : null,
      bottomNavigationBar: size.isMobile
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _switchTab(context, index),
              items: [
                for (final (icon, label) in _navItems)
                  BottomNavigationBarItem(icon: Icon(icon), label: label),
              ],
            )
          : null,
    );
  }
}

/// A floor plan dressed up for grid display: a color pulled cyclically from
/// the theme (the table has no color column) and, when the private storage
/// object resolved, a short-lived signed URL to its image.
class _ProjectView {
  const _ProjectView({required this.record, required this.accent, this.imageUrl});

  final FloorPlanRecord record;
  final Color accent;
  final String? imageUrl;

  String get title => record.displayTitle;
  String get dateLabel => _formatRelativeDate(record.uploadDateTime);
}

String _formatRelativeDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && local.day == now.day) return '${diff.inHours}h ago';
  final yesterday = now.subtract(const Duration(days: 1));
  if (local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day) {
    return 'Yesterday';
  }
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Loads the signed-in user's floor plans and resolves a short-lived signed
/// URL for each image, since the storage bucket is private.
Future<List<_ProjectView>> _loadUserProjects(AppColors c) async {
  final user = AuthService.instance.currentUser;
  if (user == null) return const [];
  final records = await FloorPlanRepository.instance.fetchUserFloorPlans(
    user.id,
  );
  final accents = [c.primary, c.accent, c.secondary, c.warning];
  final urls = await Future.wait(
    records.map((r) async {
      try {
        return await FloorPlanRepository.instance.signedUrlFor(r.imagePath);
      } catch (_) {
        return null;
      }
    }),
  );
  return [
    for (final (i, record) in records.indexed)
      _ProjectView(
        record: record,
        accent: accents[i % accents.length],
        imageUrl: urls[i],
      ),
  ];
}

/// Opens the right next step for a floor plan: the processing screen if its
/// AI analysis isn't ready yet (it will forward on automatically once it
/// is), or straight to room selection if rooms are already detected.
void _openProject(BuildContext context, FloorPlanRecord record) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProcessingScreen(floorPlan: record),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppUserProfile? _profile;
  bool _isAdmin = false;
  List<_ProjectView>? _projects;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profile == null && _projects == null) _load();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final c = context.colors;
    final results = await Future.wait([
      UserRepository.instance.fetchProfile(user.id),
      AuthService.instance.isAdmin(),
      _loadUserProjects(c),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as AppUserProfile?;
      _isAdmin = results[1] as bool;
      _projects = results[2] as List<_ProjectView>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      selectedIndex: 0,
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-upload',
        onPressed: () => _switchTab(context, 2),
        tooltip: 'New upload',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _DashboardContent(
          size: context.screenSize,
          profile: _profile,
          isAdmin: _isAdmin,
          projects: _projects,
          onSeeAll: () => _switchTab(context, 1),
          onUpload: () => _switchTab(context, 2),
          onAvatarTap: () => _switchTab(context, 3),
          onProjectTap: (p) => _openProject(context, p.record),
          onAdminTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminAccountsScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.size,
    required this.profile,
    required this.isAdmin,
    required this.projects,
    required this.onSeeAll,
    required this.onUpload,
    required this.onAvatarTap,
    required this.onProjectTap,
    required this.onAdminTap,
  });

  final ScreenSize size;
  final AppUserProfile? profile;
  final bool isAdmin;
  final List<_ProjectView>? projects;
  final VoidCallback onSeeAll;
  final VoidCallback onUpload;
  final VoidCallback onAvatarTap;
  final ValueChanged<_ProjectView> onProjectTap;
  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    final hero = _HeroBanner(onUpload: onUpload);
    final recent = projects?.take(4).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: AppContentFrame(
        // Keeps the last row clear of the mobile floating action button.
        bottomInset: size.isMobile ? 72 : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              profile: profile,
              isAdmin: isAdmin,
              onAvatarTap: onAvatarTap,
              onAdminTap: onAdminTap,
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (size.isDesktop)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: hero),
                    const SizedBox(width: AppSpacing.xl),
                    const Expanded(flex: 2, child: _TipCard(vertical: true)),
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
            _ProjectGrid(
              projects: recent,
              emptyAction: onUpload,
              onTap: onProjectTap,
            ),
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

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.isAdmin,
    required this.onAvatarTap,
    required this.onAdminTap,
  });

  final AppUserProfile? profile;
  final bool isAdmin;
  final VoidCallback onAvatarTap;
  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final firstName = profile?.fullName.trim().split(RegExp(r'\s+')).first;

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
                    profile?.initials ?? '',
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
                firstName == null ? _greeting() : '${_greeting()}, $firstName',
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
        if (isAdmin) ...[
          actionButton(
            icon: Icons.admin_panel_settings_outlined,
            tooltip: 'Manage accounts',
            onPressed: onAdminTap,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
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
  const _HeroBanner({required this.onUpload});

  final VoidCallback onUpload;

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
                        onPressed: onUpload,
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

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.projects,
    required this.emptyAction,
    required this.onTap,
  });

  /// Null while still loading; empty once loaded with nothing to show.
  final List<_ProjectView>? projects;
  final VoidCallback emptyAction;
  final ValueChanged<_ProjectView> onTap;

  @override
  Widget build(BuildContext context) {
    final list = projects;
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (list.isEmpty) {
      return _EmptyProjects(onUpload: emptyAction);
    }

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
        for (final (index, project) in list.indexed)
          _ProjectCard(
            project: project,
            planIndex: index,
            onTap: () => onTap(project),
          ),
      ],
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.grid_view_rounded, color: c.textMuted, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text('No projects yet', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Upload a floor plan to start your first AI design.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Upload floor plan',
            icon: Icons.cloud_upload_outlined,
            expanded: false,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.planIndex,
    required this.onTap,
  });

  final _ProjectView project;
  final int planIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final imageUrl = project.imageUrl;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
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
              )
            else
              ColoredBox(
                color: c.surfaceElevated,
                child: CustomPaint(
                  painter: _PlanPainter(
                    accent: project.accent,
                    lineColor: c.textPrimary,
                    variant: planIndex,
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
                                  project.dateLabel,
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
              children: [
                icon,
                const SizedBox(height: AppSpacing.md),
                message,
              ],
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
