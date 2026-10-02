part of 'main.dart';

/// The full list behind the dashboard's "Recent Projects" preview and the
/// "Projects" tab. Supports a simple name search; there's no backend yet, so
/// both this screen and the dashboard read from the same mock data.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<_ProjectView>? _projects;
  bool _loadFailed = false;

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
    final c = context.colors;
    final text = context.text;
    final projects = _projects;
    final query = _query.trim().toLowerCase();
    final results = projects == null
        ? null
        : query.isEmpty
        ? projects
        : projects.where((p) => p.title.toLowerCase().contains(query)).toList();

    return _TabScaffold(
      selectedIndex: 1,
      appBar: AppBar(title: const Text('Your projects')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-project',
        onPressed: () => _switchTab(context, 2),
        tooltip: 'New project',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppContentFrame(
            bottomInset: context.screenSize.isMobile ? 72 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projects == null
                      ? 'Loading projects'
                      : '${projects.length} project${projects.length == 1 ? '' : 's'}',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Every floor plan you have turned into an AI design.',
                  style: text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.xl),
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
                      ? _EmptyProjects(onUpload: () => _switchTab(context, 2))
                      : _NoResults(query: _query)
                else
                  AppResponsiveGrid(
                    mobileColumns: 2,
                    tabletColumns: 3,
                    desktopColumns: 4,
                    childAspectRatio: context.responsive(
                      mobile: 0.88,
                      tablet: 1.0,
                      desktop: 1.1,
                    ),
                    children: [
                      for (final (index, project) in results.indexed)
                        _ProjectCard(
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
