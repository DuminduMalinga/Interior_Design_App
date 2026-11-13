part of 'main.dart';

/// The full list behind the dashboard's "Recent Projects" preview and the
/// "Projects" tab. Supports a simple name search; there's no backend yet, so
/// both this screen and the dashboard read from the same mock data.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key}) : _preview = null;

  /// Shows [projects] as if they had just loaded, without the database.
  const ProjectsScreen._preview(List<_ProjectView> projects)
    : _preview = projects;

  final List<_ProjectView>? _preview;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _stage = 'All';
  List<_ProjectView>? _projects;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _projects = widget._preview;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_projects == null) _load();
  }

  Future<void> _load() async {
    final colors = context.colors;
    setState(() => _loadFailed = false);
    try {
      final projects = await _loadUserProjects(colors);
      if (!mounted) return;
      setState(() => _projects = projects);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = _projects;
    final query = _query.trim().toLowerCase();
    final results = projects
        ?.where((p) => _stage == 'All' || p.summary.stage.label == _stage)
        .where(
          (p) =>
              query.isEmpty ||
              p.title.toLowerCase().contains(query) ||
              p.summary.stage.label.toLowerCase().contains(query),
        )
        .toList();

    return _TabScaffold(
      selectedIndex: 1,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppContentFrame(
            bottomInset: context.screenSize.isMobile ? AppSpacing.xl : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTabHeader(
                  title: 'Projects',
                  caption: projects == null
                      ? 'Loading projects'
                      : '${projects.length} floor plan'
                            '${projects.length == 1 ? '' : 's'} · '
                            '${projects.where((p) => p.summary.stage.isFinished).length} finished',
                  actionIcon: Icons.refresh_rounded,
                  actionTooltip: 'Refresh projects',
                  onAction: _load,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInputField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  hintText: 'Search projects',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppFilterChips(
                  labels: const [
                    'All',
                    'Uploaded',
                    'Rooms detected',
                    'Layouts ready',
                    'Layout chosen',
                  ],
                  selected: _stage,
                  onSelected: (v) => setState(() => _stage = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_loadFailed && results == null)
                  _LoadError(onRetry: _load)
                else if (results == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (results.isEmpty)
                  _query.isEmpty
                      ? _EmptyProjects(onUpload: () => _switchTab(context, 3))
                      : _NoResults(query: _query)
                else
                  AppResponsiveGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 3,
                    childAspectRatio: context.responsive(
                      mobile: 3.3,
                      tablet: 3.3,
                      desktop: 3.1,
                    ),
                    children: [
                      for (final (index, project) in results.indexed)
                        _ProjectRow(
                          project: project,
                          planIndex: index,
                          onTap: () => _openProject(context, project.record),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic "couldn't load" state with a retry action. Deliberately shows no
/// backend error detail to the user (SRS FR31/FR32).
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: c.textMuted, size: 46),
            const SizedBox(height: AppSpacing.lg),
            Text('Something went wrong', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message ?? 'We could not load this right now. Please try again.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// One project as a row: a plan thumbnail, its name and score, its stage and
/// what to do next.
class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
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
    final summary = project.summary;
    final score = summary.score;
    final imageUrl = project.imageUrl;

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
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: imageUrl == null
                  ? sketch()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => sketch(),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                    ),
                    if (score != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$score',
                        style: text.labelLarge?.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ProjectStageChip(stage: summary.stage),
                const SizedBox(height: 6),
                Text(
                  'Next: ${summary.stage.nextStep}',
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
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: c.textMuted, size: 46),
            const SizedBox(height: AppSpacing.lg),
            Text('No projects match "$query"', style: context.text.titleSmall),
          ],
        ),
      ),
    );
  }
}

/// The projects tab listing [summaries], without the database.
@visibleForTesting
Widget projectsPreviewForTest(List<ProjectSummary> summaries) =>
    ProjectsScreen._preview(_previewViews(summaries));
