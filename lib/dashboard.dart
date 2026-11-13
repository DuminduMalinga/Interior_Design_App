part of 'main.dart';

const _navItems = [
  (Icons.home_rounded, 'Home'),
  (Icons.grid_view_rounded, 'Projects'),
  (Icons.bookmarks_outlined, 'Designs'),
  (Icons.cloud_upload_outlined, 'Upload'),
  (Icons.person_outline_rounded, 'Profile'),
];

/// Switches to one of the five tab screens.
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
    2 => const DesignsScreen(),
    3 => const UploadScreen(),
    4 => const ProfileScreen(),
    _ => const DashboardScreen(),
  };
  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Shared chrome for the five tab screens: a bottom nav on mobile or a side
/// rail on wider screens. Every tab screen renders through this so the nav
/// stays visually identical — and present — no matter which tab is active.
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.selectedIndex, required this.body});

  final int selectedIndex;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;

    return Scaffold(
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
      bottomNavigationBar: size.isMobile
          ? _FloatingNavBar(
              selectedIndex: selectedIndex,
              onSelected: (index) => _switchTab(context, index),
            )
          : null,
    );
  }
}

/// The floating pill navigation: the active tab shows its label, the Upload
/// tab is a gold action button, the rest are icons.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const int _uploadIndex = 3;

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.fullAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (i, (icon, label)) in _navItems.indexed)
                _item(context, i, icon, label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, IconData icon, String label) {
    final c = context.colors;
    final selected = i == selectedIndex;
    final isUpload = i == _uploadIndex;
    final fg = isUpload
        ? c.onPrimary
        : (selected ? c.textPrimary : c.textMuted);
    final bg = isUpload
        ? c.primary
        : (selected ? c.surfaceElevated : Colors.transparent);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bg,
        borderRadius: AppRadius.fullAll,
        child: InkWell(
          borderRadius: AppRadius.fullAll,
          onTap: () => onSelected(i),
          child: SizedBox(
            height: 48,
            width: selected && !isUpload ? null : 48,
            child: Padding(
              padding: selected && !isUpload
                  ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
                  : EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: AppIconSize.md, color: fg),
                  if (selected && !isUpload) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: context.text.labelMedium?.copyWith(color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A floor plan dressed up for grid display: a color pulled cyclically from
/// the theme (the table has no color column) and, when the private storage
/// object resolved, a short-lived signed URL to its image.
class _ProjectView {
  const _ProjectView({
    required this.summary,
    required this.accent,
    this.imageUrl,
  });

  /// The plan and how far it has got through the design flow.
  final ProjectSummary summary;
  final Color accent;
  final String? imageUrl;

  FloorPlanRecord get record => summary.plan;

  /// The room it was taken to, else how many rooms it has (the web's title).
  String get title => summary.title;

  /// When it last changed: its analysis, else its upload.
  String get dateLabel => _formatRelativeDate(summary.updatedAt);
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Loads the signed-in user's floor plans and resolves a short-lived signed
/// URL for each image, since the storage bucket is private.
Future<List<_ProjectView>> _loadUserProjects(AppColors c) async {
  final user = AuthService.instance.currentUser;
  if (user == null) return const [];
  final summaries = await FloorPlanRepository.instance.fetchProjects(user.id);
  final accents = [c.primary, c.accent, c.secondary, c.warning];
  final urls = await Future.wait(
    summaries.map((p) async {
      try {
        return await FloorPlanRepository.instance.signedUrlFor(
          p.plan.imagePath,
        );
      } catch (_) {
        return null;
      }
    }),
  );
  return [
    for (final (i, summary) in summaries.indexed)
      _ProjectView(
        summary: summary,
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
    final List<Object?> results;
    try {
      results = await Future.wait([
        UserRepository.instance.fetchProfile(user.id),
        AuthService.instance.isAdmin(),
        _loadUserProjects(c),
      ]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _projects = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not load your dashboard.'),
          action: SnackBarAction(label: 'Retry', onPressed: _retryLoad),
        ),
      );
      return;
    }
    if (!mounted) return;
    // The profile row is gone: an admin deleted this account while the
    // session was still valid. The web app signs the user out in that case.
    if (results[0] == null) {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(startInSignIn: true),
        ),
        (route) => false,
      );
      return;
    }
    setState(() {
      _profile = results[0] as AppUserProfile?;
      _isAdmin = results[1] as bool;
      _projects = results[2] as List<_ProjectView>;
    });
  }

  void _retryLoad() {
    setState(() {
      _profile = null;
      _projects = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      selectedIndex: 0,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _DashboardContent(
          size: context.screenSize,
          profile: _profile,
          isAdmin: _isAdmin,
          projects: _projects,
          onSeeAll: () => _switchTab(context, 1),
          onUpload: () => _switchTab(context, 3),
          onViewDesigns: () => _switchTab(context, 2),
          onAvatarTap: () => _switchTab(context, 4),
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
    required this.onViewDesigns,
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
  final VoidCallback onViewDesigns;
  final VoidCallback onAvatarTap;
  final ValueChanged<_ProjectView> onProjectTap;
  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    final recent = projects?.take(4).toList();
    final current = (projects == null || projects!.isEmpty)
        ? null
        : projects!.first;
    final stats = projects == null || projects!.isEmpty
        ? null
        : ProjectStats.of([for (final p in projects!) p.summary]);
    final hero = _HeroBanner(
      project: current,
      lastScore: stats?.lastScore,
      onUpload: onUpload,
      onOpen: current == null ? null : () => onProjectTap(current),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: AppContentFrame(
        bottomInset: size.isMobile ? AppSpacing.xl : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              profile: profile,
              isAdmin: isAdmin,
              onAvatarTap: onAvatarTap,
              onAdminTap: onAdminTap,
            ),
            const SizedBox(height: AppSpacing.xl),
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
            if (stats != null) ...[
              const SizedBox(height: AppSpacing.md),
              ProjectStatsRow(stats: stats),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Quick tools', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _QuickTool(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Upload plan',
                    caption: 'JPG or PNG,\nup to 10 MB',
                    onTap: onUpload,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickTool(
                    icon: Icons.view_in_ar_outlined,
                    title: '3D viewer',
                    caption: 'Turn, zoom and\nexport a room',
                    onTap: onViewDesigns,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Recent projects',
              actionLabel: 'See all',
              onAction: onSeeAll,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProjectGrid(
              projects: recent,
              emptyAction: onUpload,
              onTap: onProjectTap,
            ),
            if (!size.isDesktop) ...[
              const SizedBox(height: AppSpacing.xl),
              const _TipCard(),
            ],
          ],
        ),
      ),
    );
  }
}

/// A square-ish action tile: title and caption on the left, an icon top
/// right and a gold arrow button at the bottom.
class _QuickTool extends StatelessWidget {
  const _QuickTool({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: SizedBox(
        height: 88,
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
                      Text(title, style: text.titleSmall),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        style: text.labelSmall?.copyWith(
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: c.primary, size: 22),
              ],
            ),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 28,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: c.onPrimary,
                ),
              ),
            ),
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
            borderRadius: AppRadius.fullAll,
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
            child: AppAvatar(
              initials: profile?.initials ?? '',
              imageUrl: profile?.avatarUrl,
              size: 48,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
              Text(
                firstName ?? _greeting(),
                style: context.responsive(
                  mobile: text.titleLarge,
                  tablet: text.headlineSmall,
                ),
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

/// The top card of Home: the project you were last working on, with its
/// next step, and the last layout score beside it. Before there is a
/// project it invites the first upload instead.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.project,
    required this.lastScore,
    required this.onUpload,
    required this.onOpen,
  });

  final _ProjectView? project;
  final int? lastScore;
  final VoidCallback onUpload;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final p = project;
    const ink = Color(0xFFF8F4EE);
    const inkSoft = Color(0xFFEDE4D8);

    final card = Material(
      color: Color.alphaBlend(c.secondary.withValues(alpha: .55), c.surface),
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: p == null ? onUpload : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 118),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p == null ? 'Get started' : 'Current project',
                      style: text.labelMedium?.copyWith(color: inkSoft),
                    ),
                    if (p != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.background.withValues(alpha: .35),
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md - 2,
                            vertical: 4,
                          ),
                          child: Text(
                            p.summary.stage.label,
                            style: text.labelSmall?.copyWith(color: ink),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  p?.title ?? 'Turn sketches into smart floor plans.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(color: ink),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p == null
                            ? 'Upload an image and let AI do the work.'
                            : 'Next: ${p.summary.stage.nextStep}',
                        style: text.labelMedium?.copyWith(color: inkSoft),
                      ),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(
                        dimension: 32,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF1A1612),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (lastScore == null) return card;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card),
          const SizedBox(width: AppSpacing.md),
          _ScoreRing(score: lastScore!),
        ],
      ),
    );
  }
}

/// The last layout score, as a gold ring around the number.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return SizedBox(
      width: 104,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md + 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox.square(
              dimension: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: c.border,
                      color: c.primary,
                    ),
                  ),
                  Text(
                    '$score',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text('Last score', style: text.labelMedium),
                Text(
                  'Layout',
                  style: text.labelSmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
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
        mobile: 0.8,
        tablet: 1.0,
        desktop: 1.05,
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
    final summary = project.summary;
    final score = summary.score;

    Widget sketch() => ColoredBox(
      color: c.surfaceElevated,
      child: CustomPaint(
        painter: _PlanPainter(
          accent: project.accent,
          lineColor: c.textPrimary,
          variant: planIndex,
        ),
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.mdAll,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => sketch(),
                    )
                  else
                    sketch(),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ProjectStageChip(stage: summary.stage),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 2,
                AppSpacing.md,
                AppSpacing.md,
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
                        const SizedBox(height: 2),
                        Text(
                          summary.stage.nextStep,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(color: c.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: c.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (score != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: text.titleMedium?.copyWith(
                            color: _scoreStatus(score).colorIn(c),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/100',
                          style: text.labelSmall?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
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
      color: c.primary,
      size: vertical ? 28 : 22,
    );
    final message = Text(
      'Pro tip: Clear, top-down photos give the most accurate AI results.',
      style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
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

/// One project card for [summary], so tests can see it without the screens
/// that load projects from the database.
@visibleForTesting
Widget projectCardForTest(
  ProjectSummary summary, {
  VoidCallback? onTap,
  String? imageUrl,
}) => _ProjectCard(
  project: _ProjectView(
    summary: summary,
    accent: Colors.indigo,
    imageUrl: imageUrl,
  ),
  planIndex: 0,
  onTap: onTap ?? () {},
);

List<_ProjectView> _previewViews(List<ProjectSummary> summaries) => [
  for (final summary in summaries)
    _ProjectView(summary: summary, accent: const Color(0xFFC9AE86)),
];

/// Home for [profile] with these projects, without the database.
@visibleForTesting
Widget dashboardPreviewForTest({
  required AppUserProfile profile,
  required List<ProjectSummary> summaries,
}) => Builder(
  builder: (context) => _TabScaffold(
    selectedIndex: 0,
    body: _DashboardContent(
      size: context.screenSize,
      profile: profile,
      isAdmin: false,
      projects: _previewViews(summaries),
      onSeeAll: () {},
      onUpload: () {},
      onViewDesigns: () {},
      onAvatarTap: () {},
      onProjectTap: (_) {},
      onAdminTap: () {},
    ),
  ),
);
