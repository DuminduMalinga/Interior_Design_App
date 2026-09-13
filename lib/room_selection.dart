part of 'main.dart';

/// Shown after [ProcessingScreen] finishes analyzing the uploaded floor plan.
///
/// Presents the AI-detected rooms as an interactive top-down diagram plus a
/// list of tappable cards, each annotated with an AI "suitability" score so
/// the user can judge how well a room fits before continuing.
class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({super.key});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _DetectedRoom {
  const _DetectedRoom({
    required this.name,
    required this.icon,
    required this.color,
    required this.bounds,
    required this.suitability,
    required this.note,
  });

  final String name;
  final IconData icon;
  final Color color;

  /// Fractional bounds (0-1) within the floor plan diagram.
  final Rect bounds;

  /// AI confidence/suitability score out of 100.
  final int suitability;
  final String note;

  String get tag {
    if (suitability >= 90) return 'Excellent fit';
    if (suitability >= 75) return 'Great fit';
    return 'Good fit';
  }
}

const _detectedRooms = [
  _DetectedRoom(
    name: 'Living Room',
    icon: Icons.weekend_outlined,
    color: _blue,
    bounds: Rect.fromLTWH(0, 0, .58, .62),
    suitability: 96,
    note: 'Bright, open layout — ideal for a statement centerpiece.',
  ),
  _DetectedRoom(
    name: 'Kitchen',
    icon: Icons.kitchen_outlined,
    color: Color(0xFF35C5B5),
    bounds: Rect.fromLTWH(.6, 0, .4, .38),
    suitability: 88,
    note: 'Efficient galley shape close to the dining area.',
  ),
  _DetectedRoom(
    name: 'Bedroom',
    icon: Icons.bed_outlined,
    color: _violet,
    bounds: Rect.fromLTWH(.6, .42, .4, .58),
    suitability: 74,
    note: 'Cozy corner room with limited natural light.',
  ),
];

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final room = _detectedRooms[_selected];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Select a room',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AiPill(),
              const SizedBox(height: 13),
              const Text(
                'We found 3 rooms',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Tap a room on the plan or in the list to see how well it '
                'suits an AI redesign.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              _FloorPlanDiagram(
                rooms: _detectedRooms,
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
              ),
              const SizedBox(height: 24),
              const Text(
                'Detected rooms',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _detectedRooms.length; i++) ...[
                _RoomCard(
                  room: _detectedRooms[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
                if (i != _detectedRooms.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_blue, _violet]),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: .24),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmSelection(context, room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(
                      'Design the ${room.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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

  void _confirmSelection(BuildContext context, _DetectedRoom room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text('${room.name} selected — style picker coming soon.'),
      ),
    );
  }
}

/// Interactive top-down floor plan with each detected room drawn as a
/// distinct colored overlay. Tapping a region selects that room.
class _FloorPlanDiagram extends StatelessWidget {
  const _FloorPlanDiagram({
    required this.rooms,
    required this.selected,
    required this.onSelect,
  });

  final List<_DetectedRoom> rooms;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onTapUp: (details) {
              for (var i = rooms.length - 1; i >= 0; i--) {
                final rect = Rect.fromLTWH(
                  rooms[i].bounds.left * size.width,
                  rooms[i].bounds.top * size.height,
                  rooms[i].bounds.width * size.width,
                  rooms[i].bounds.height * size.height,
                );
                if (rect.contains(details.localPosition)) {
                  onSelect(i);
                  return;
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: .08),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: CustomPaint(
                painter: _FloorPlanPainter(rooms: rooms, selected: selected),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter({required this.rooms, required this.selected});

  final List<_DetectedRoom> rooms;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(Offset.zero & size, outline);

    for (var i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final isSelected = i == selected;
      final rect = Rect.fromLTWH(
        room.bounds.left * size.width,
        room.bounds.top * size.height,
        room.bounds.width * size.width,
        room.bounds.height * size.height,
      ).deflate(2.5);

      if (isSelected) {
        final glow = Paint()
          ..color = room.color.withValues(alpha: .35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawRect(rect, glow);
      }

      final fill = Paint()
        ..color = room.color.withValues(alpha: isSelected ? .30 : .14);
      canvas.drawRect(rect, fill);

      final border = Paint()
        ..color = room.color.withValues(alpha: isSelected ? 1 : .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1.2;
      canvas.drawRect(rect, border);

      _paintLabel(canvas, rect, room, isSelected);
    }
  }

  void _paintLabel(
    Canvas canvas,
    Rect rect,
    _DetectedRoom room,
    bool isSelected,
  ) {
    final iconSpan = TextSpan(
      text: String.fromCharCode(room.icon.codePoint),
      style: TextStyle(
        fontSize: 15,
        fontFamily: room.icon.fontFamily,
        package: room.icon.fontPackage,
        color: Colors.white,
      ),
    );
    final labelSpan = TextSpan(
      text: '  ${room.name}',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
    final painter = TextPainter(
      text: TextSpan(children: [iconSpan, labelSpan]),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 12);

    final pillWidth = painter.width + 16;
    final pillHeight = painter.height + 10;
    if (pillWidth > rect.width + 4) return;

    final pillRect = Rect.fromLTWH(
      rect.left + 7,
      rect.top + 7,
      pillWidth,
      pillHeight,
    );
    final pillPaint = Paint()
      ..color = room.color.withValues(alpha: isSelected ? .9 : .55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      pillPaint,
    );
    painter.paint(canvas, pillRect.topLeft + const Offset(8, 5));
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.rooms != rooms;
}

/// A tappable card summarizing a detected room and its AI suitability score.
class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  final _DetectedRoom room;
  final bool selected;
  final VoidCallback onTap;

  Color get _scoreColor {
    if (room.suitability >= 90) return const Color(0xFF4ADE80);
    if (room.suitability >= 75) return const Color(0xFF4D9BFF);
    return const Color(0xFFF6C86A);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: .08) : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _blue.withValues(alpha: .55)
                : Colors.white.withValues(alpha: .07),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: room.color.withValues(alpha: .18),
                border: Border.all(color: room.color.withValues(alpha: .4)),
              ),
              child: Icon(room.icon, color: room.color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _SuitabilityBadge(
                        score: room.suitability,
                        color: _scoreColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.tag,
                    style: TextStyle(
                      color: _scoreColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.note,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: room.suitability / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: .08),
                      valueColor: AlwaysStoppedAnimation(_scoreColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? _blue : Colors.white.withValues(alpha: .18),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuitabilityBadge extends StatelessWidget {
  const _SuitabilityBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        '$score% match',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
