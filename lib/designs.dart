part of 'main.dart';

/// The "Designs" tab: every furnished room the user saved, newest first, as
/// the web dashboard's "My Designs" lists them. Designs saved on the web
/// show here too, and the reverse.
class DesignsScreen extends StatefulWidget {
  const DesignsScreen({super.key});

  @override
  State<DesignsScreen> createState() => _DesignsScreenState();
}

class _DesignsScreenState extends State<DesignsScreen> {
  List<SavedDesignRecord>? _designs;
  bool _loadFailed = false;

  /// Designs being removed, so their delete button shows progress.
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final user = AuthService.instance.currentUser;
      final designs = user == null
          ? const <SavedDesignRecord>[]
          : await SavedDesignRepository.instance.list(user.id);
      if (!mounted) return;
      setState(() => _designs = designs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _delete(SavedDesignRecord design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove design?'),
        content: Text(
          'Remove the saved design for the ${design.roomName}? '
          'The floor plan and its layouts stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting.add(design.designId));
    try {
      await SavedDesignRepository.instance.delete(design);
      if (!mounted) return;
      setState(
        () => _designs?.removeWhere((d) => d.designId == design.designId),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Design removed.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the design. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting.remove(design.designId));
    }
  }

  void _open3D(SavedDesignRecord design, AnalysisLayout layout) {
    final room = _DetectedRoom(
      roomId: design.roomId,
      name: design.roomName,
      icon: _iconForRoomType(design.roomName),
      accent: _RoomAccent.primary,
      bounds: Rect.zero,
      suitability: design.score ?? 0,
      note: '',
      fromAnalysis: true,
    );
    final option = _LayoutOption(
      layoutId: layout.type,
      title: design.title ?? layout.title,
      tags: const [],
      matchScore: (design.score ?? 0).clamp(0, 100),
      variant: 0,
      furniture: const [],
      analysis: layout,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Room3DViewerScreen(room: room, layout: option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final designs = _designs;

    return _TabScaffold(
      selectedIndex: 2,
      appBar: AppBar(title: const Text('My designs')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  designs == null
                      ? 'Loading designs'
                      : '${designs.length} saved design'
                            '${designs.length == 1 ? '' : 's'}',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Rooms you furnished and saved, here or on the web.',
                  style: text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_loadFailed && designs == null)
                  _LoadError(onRetry: _load)
                else if (designs == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (designs.isEmpty)
                  _EmptyDesigns(onBrowse: () => _switchTab(context, 1))
                else
                  AppResponsiveGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 3,
                    childAspectRatio: context.responsive(
                      mobile: 1.0,
                      tablet: 0.9,
                      desktop: 0.95,
                    ),
                    children: [
                      for (final design in designs)
                        _SavedDesignCard(
                          design: design,
                          deleting: _deleting.contains(design.designId),
                          onOpen: design.layout == null
                              ? null
                              : () => _open3D(design, design.layout!),
                          onDelete: () => _delete(design),
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

class _EmptyDesigns extends StatelessWidget {
  const _EmptyDesigns({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.bookmarks_outlined, color: c.textMuted, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text('No saved designs yet', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Open a project, pick a room and confirm a layout to save it here.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Go to projects',
            icon: Icons.grid_view_rounded,
            expanded: false,
            onPressed: onBrowse,
          ),
        ],
      ),
    );
  }
}

/// One saved design: its preview picture (saved by the web's 3D view) or,
/// failing that, the layout drawn as a plan; then the room, layout and date.
class _SavedDesignCard extends StatelessWidget {
  const _SavedDesignCard({
    required this.design,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
  });

  final SavedDesignRecord design;
  final bool deleting;

  /// Null when the saved layout can't be read, so there is nothing to show.
  final VoidCallback? onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final layout = design.layout;
    final score = design.score;

    Widget plan() => layout == null
        ? Center(
            child: Icon(Icons.view_in_ar_rounded, color: c.textMuted, size: 36),
          )
        : Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CustomPaint(
              painter: _AnalysisPlanPainter(
                layout: layout,
                wall: c.textPrimary.withValues(alpha: 0.35),
                door: c.accent,
                window: c.secondary,
                colorFor: (t) => _furnitureColor(t, c),
              ),
              size: Size.infinite,
            ),
          );

    final previewUrl = design.previewUrl;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: c.surfaceElevated,
                    child: previewUrl == null
                        ? plan()
                        : Image.network(
                            previewUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                plan(),
                          ),
                  ),
                  if (score != null)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: AppStatusChip(
                        label: '$score/100',
                        status: _scoreStatus(score),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          design.roomName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                        Text(
                          [
                            ?design.title,
                            _formatRelativeDate(design.updatedAt),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onOpen != null)
                    IconButton(
                      tooltip: 'Open in 3D',
                      icon: const Icon(Icons.view_in_ar_rounded),
                      onPressed: onOpen,
                    ),
                  IconButton(
                    tooltip: 'Remove design',
                    onPressed: deleting ? null : onDelete,
                    icon: deleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.delete_outline_rounded, color: c.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
