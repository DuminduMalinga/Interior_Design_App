part of 'main.dart';

/// Shown after the user confirms a room on [RoomSelectionScreen].
///
/// Presents a swipeable deck of AI-generated furniture layout options for
/// that room, each scored against how well it suits the room the AI
/// detected earlier.
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
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'AI layouts',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(room.icon, color: room.color, size: 18),
                      const SizedBox(width: 7),
                      Text(
                        'Layouts for the ${room.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Based on this room\'s '),
                        TextSpan(
                          text: '${room.suitability}% suitability',
                          style: TextStyle(
                            color: room.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: ', swipe to compare AI-scored layouts.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
                      horizontal: 8,
                      vertical: isActive ? 0 : 18,
                    ),
                    child: _LayoutCard(room: room, layout: _layouts[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                      color: i == _page
                          ? room.color
                          : Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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

  Color get _scoreColor {
    if (layout.matchScore >= 90) return const Color(0xFF4ADE80);
    if (layout.matchScore >= 75) return const Color(0xFF4D9BFF);
    return const Color(0xFFF6C86A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: room.color.withValues(alpha: .10),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: const Color(0xFF171E2C),
                      child: CustomPaint(
                        painter: _LayoutRenderPainter(
                          accent: room.color,
                          variant: layout.variant,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _MatchBadge(score: layout.matchScore, color: _scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Text(
            layout.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in layout.tags) _StyleTag(label: tag),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _view3D(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: room.color.withValues(alpha: .55)),
                backgroundColor: room.color.withValues(alpha: .10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.view_in_ar_outlined, size: 18),
              label: const Text(
                'View in 3D',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _view3D(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text('3D view for "${layout.title}" coming soon.'),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC0D111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            '$score% match',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleTag extends StatelessWidget {
  const _StyleTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A stylized top-down render of a furnished layout, distinguished per
/// [variant] so each swiped card reads as a distinct arrangement.
class _LayoutRenderPainter extends CustomPainter {
  const _LayoutRenderPainter({required this.accent, required this.variant});

  final Color accent;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final wall = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(room, wall);

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

    final rug = Paint()
      ..color = accent.withValues(alpha: .10)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(room.deflate(room.width * .18), const Radius.circular(10)),
      rug,
    );
  }

  @override
  bool shouldRepaint(covariant _LayoutRenderPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.variant != variant;
}
