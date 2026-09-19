part of 'main.dart';

/// Shown after the user confirms a room on [RoomSelectionScreen].
///
/// Presents AI-generated furniture layout options for that room, each scored
/// against how well it suits the room the AI detected earlier. Phones get a
/// swipeable deck; wider screens get a grid so options can be compared.
// ignore_for_file: library_private_types_in_public_api
// `_DetectedRoom` is private to this app's single-library `part` setup
// (declared in room_selection.dart), not a leaked implementation detail.
class LayoutsScreen extends StatefulWidget {
  const LayoutsScreen({required this.room, super.key});

  final _DetectedRoom room;

  @override
  State<LayoutsScreen> createState() => _LayoutsScreenState();
}

class _LayoutOption {
  const _LayoutOption({
    required this.title,
    required this.tags,
    required this.matchScore,
    required this.variant,
  });

  final String title;
  final List<String> tags;
  final int matchScore;
  final int variant;
}

class _LayoutsScreenState extends State<LayoutsScreen> {
  late final PageController _pageController;
  int _page = 0;
  late final List<_LayoutOption> _layouts;

  static const _archetypes = [
    ('Open & Airy', ['Minimalist', 'Natural light']),
    ('Warm Gathering', ['Scandinavian', 'Warm woods']),
    ('Cozy Corner', ['Modern', 'Soft textures']),
    ('Compact Efficient', ['Space-saving', 'Multi-use']),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .86);
    final base = widget.room.suitability;
    _layouts = [
      for (var i = 0; i < _archetypes.length; i++)
        _LayoutOption(
          title: _archetypes[i].$1,
          tags: _archetypes[i].$2,
          matchScore: (base - i * 6).clamp(52, 99),
          variant: i,
        ),
    ]..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final room = widget.room;
    final roomColor = room.colorIn(c);
    final isMobile = context.screenSize.isMobile;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(room.icon, color: roomColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Layouts for the ${room.name}',
                style: context.responsive(
                  mobile: text.headlineSmall,
                  tablet: text.headlineLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
            children: [
              const TextSpan(text: "Based on this room's "),
              TextSpan(
                text: '${room.suitability}% suitability',
                style: text.bodyMedium?.copyWith(
                  color: roomColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: isMobile
                    ? ', swipe to compare AI-scored layouts.'
                    : ', compare the AI-scored layouts below.',
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('AI layouts'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: isMobile
              ? _buildDeck(context, header, roomColor)
              : _buildGrid(context, header),
        ),
      ),
    );
  }

  Widget _buildDeck(BuildContext context, Widget header, Color roomColor) {
    final c = context.colors;
    final room = widget.room;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            0,
          ),
          child: header,
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _layouts.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final isActive = index == _page;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: isActive ? 0 : AppSpacing.lg,
                ),
                child: _LayoutCard(room: room, layout: _layouts[index]),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _layouts.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? roomColor : c.border,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, Widget header) {
    return SingleChildScrollView(
      child: AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSpacing.xxl),
            AppResponsiveGrid(
              tabletColumns: 2,
              desktopColumns: 4,
              spacing: AppSpacing.xl,
              childAspectRatio: context.responsive(
                mobile: 1,
                tablet: 0.95,
                desktop: 0.78,
              ),
              children: [
                for (final layout in _layouts)
                  _LayoutCard(room: widget.room, layout: layout),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({required this.room, required this.layout});

  final _DetectedRoom room;
  final _LayoutOption layout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roomColor = room.colorIn(c);

    return AppCard(
      radius: AppRadius.xlAll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: ColoredBox(
                      color: c.backgroundElevated,
                      child: CustomPaint(
                        painter: _LayoutRenderPainter(
                          accent: roomColor,
                          wall: c.textPrimary.withValues(alpha: 0.3),
                          variant: layout.variant,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.backgroundElevated.withValues(alpha: 0.85),
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: AppStatusChip(
                      label: '${layout.matchScore}% match',
                      status: _scoreStatus(layout.matchScore),
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(layout.title, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm - 2,
            runSpacing: AppSpacing.sm - 2,
            children: [
              for (final tag in layout.tags) AppStatusChip(label: tag),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _view3D(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              side: BorderSide(color: roomColor.withValues(alpha: 0.55)),
              backgroundColor: roomColor.withValues(alpha: 0.10),
            ),
            icon: const Icon(Icons.view_in_ar_outlined, size: 18),
            label: const Text('View in 3D'),
          ),
        ],
      ),
    );
  }

  void _view3D(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Room3DViewerScreen(room: room, layout: layout),
      ),
    );
  }
}

/// A stylized top-down render of a furnished layout, distinguished per
/// [variant] so each swiped card reads as a distinct arrangement.
class _LayoutRenderPainter extends CustomPainter {
  const _LayoutRenderPainter({
    required this.accent,
    required this.wall,
    required this.variant,
  });

  final Color accent;
  final Color wall;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(
      room,
      Paint()
        ..color = wall
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final furnitureFill = Paint()..color = accent.withValues(alpha: .38);
    final furnitureStroke = Paint()
      ..color = accent.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pieces = switch (variant % 4) {
      0 => [
        Rect.fromLTWH(room.left + 10, room.top + 12, room.width * .42, 26),
        Rect.fromLTWH(
          room.left + room.width * .55,
          room.top + 14,
          room.width * .32,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + 12,
          room.bottom - room.height * .32,
          room.width * .5,
          room.height * .24,
        ),
      ],
      1 => [
        Rect.fromLTWH(
          room.left + room.width * .08,
          room.top + room.height * .1,
          room.width * .3,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + room.width * .45,
          room.top + room.height * .12,
          room.width * .45,
          room.height * .22,
        ),
        Rect.fromLTWH(
          room.left + room.width * .45,
          room.bottom - room.height * .35,
          room.width * .45,
          room.height * .25,
        ),
      ],
      2 => [
        Rect.fromLTWH(
          room.left + room.width * .1,
          room.top + room.height * .08,
          room.width * .8,
          room.height * .22,
        ),
        Rect.fromLTWH(
          room.left + room.width * .12,
          room.bottom - room.height * .34,
          room.width * .34,
          room.height * .26,
        ),
        Rect.fromLTWH(
          room.left + room.width * .55,
          room.bottom - room.height * .34,
          room.width * .34,
          room.height * .26,
        ),
      ],
      _ => [
        Rect.fromLTWH(
          room.left + room.width * .12,
          room.top + room.height * .14,
          room.width * .3,
          room.height * .3,
        ),
        Rect.fromLTWH(
          room.left + room.width * .5,
          room.top + room.height * .14,
          room.width * .38,
          room.height * .18,
        ),
        Rect.fromLTWH(
          room.left + room.width * .5,
          room.bottom - room.height * .3,
          room.width * .38,
          room.height * .2,
        ),
      ],
    };

    for (final piece in pieces) {
      final rrect = RRect.fromRectAndRadius(piece, const Radius.circular(6));
      canvas.drawRRect(rrect, furnitureFill);
      canvas.drawRRect(rrect, furnitureStroke);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        room.deflate(room.width * .18),
        const Radius.circular(10),
      ),
      Paint()
        ..color = accent.withValues(alpha: .10)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LayoutRenderPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.wall != wall ||
      oldDelegate.variant != variant;
}
