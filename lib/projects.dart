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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final projects = _mockProjects(c);
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? projects
        : projects.where((p) => p.title.toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Your projects'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppContentFrame(
              bottomInset: context.screenSize.isMobile ? 72 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${projects.length} project${projects.length == 1 ? '' : 's'}',
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
                  if (results.isEmpty)
                    _NoResults(query: _query)
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
                          _ProjectCard(project: project, planIndex: index),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-project',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const UploadScreen()),
        ),
        tooltip: 'New project',
        child: const Icon(Icons.add_rounded, size: 28),
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
