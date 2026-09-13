part of 'main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onNotificationTap: () {}),
                  const SizedBox(height: 28),
                  const _HeroBanner(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Recent Projects',
                    action: 'See all',
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                  const SizedBox(height: 14),
                  const _ProjectGrid(),
                  const SizedBox(height: 26),
                  const _TipCard(),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 86,
              child: FloatingActionButton(
                heroTag: 'new-upload',
                onPressed: () => _openUpload(context),
                tooltip: 'New upload',
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 8,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onSelected: (index) {
          if (index == 2) {
            _openUpload(context);
          } else {
            setState(() => _selectedTab = index);
          }
        },
      ),
    );
  }

  void _openUpload(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UploadScreen()),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_violet, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Center(
            child: Text(
              'JM',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, Jamie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Ready to design something great?',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: onNotificationTap,
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white10),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 21),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF182A58), Color(0xFF171A3D), Color(0xFF171328)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _blue.withValues(alpha: .25)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -42,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _violet.withValues(alpha: .16),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: .2),
                    blurRadius: 55,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AiPill(),
                SizedBox(height: 13),
                Text(
                  'Turn sketches into\nsmart floor plans.',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Upload an image and let AI do the work.',
                  style: TextStyle(color: Color(0xFFB8C6EE), fontSize: 11),
                ),
              ],
            ),
          ),
          Positioned(
            right: 23,
            bottom: 16,
            child: Transform.rotate(
              angle: -.08,
              child: const SizedBox(
                width: 86,
                height: 100,
                child: CustomPaint(painter: _PlanPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPill extends StatelessWidget {
  const _AiPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withValues(alpha: .35)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF83B9FF),
              size: 13,
            ),
            SizedBox(width: 5),
            Text(
              'POWERED BY AI',
              style: TextStyle(
                color: Color(0xFFB9D5FF),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: _blue,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid();

  static const projects = [
    (
      'Loft Apartment',
      'Just now',
      _blue,
      'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=900&q=85',
    ),
    (
      'Coastal Retreat',
      'Yesterday',
      Color(0xFF35C5B5),
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=900&q=85',
    ),
    (
      'Studio Workspace',
      'Aug 24, 2024',
      _violet,
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=85',
    ),
    (
      'Family Residence',
      'Aug 18, 2024',
      Color(0xFFE29C61),
      'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=900&q=85',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .91,
      ),
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(
          title: project.$1,
          date: project.$2,
          accent: project.$3,
          imageUrl: project.$4,
          planIndex: index,
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.date,
    required this.accent,
    required this.imageUrl,
    required this.planIndex,
  });

  final String title;
  final String date;
  final Color accent;
  final String imageUrl;
  final int planIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: const Color(0xFF1B2230),
                child: CustomPaint(
                  painter: _PlanPainter(accent: accent, variant: planIndex),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .08),
                    Colors.black.withValues(alpha: .88),
                  ],
                  stops: const [.35, .52, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 10,
              bottom: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFD1D7E5),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFFD1D7E5),
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white.withValues(alpha: .8),
                        size: 18,
                      ),
                    ],
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

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _blue.withValues(alpha: .15)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFF6C86A),
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Pro tip: Clear, top-down photos give the most accurate AI results.',
              style: TextStyle(
                color: Color(0xFFB5C3DD),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.grid_view_rounded, 'Projects'),
      (Icons.cloud_upload_outlined, 'Upload'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onSelected,
      backgroundColor: const Color(0xFF0D111D),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _blue,
      unselectedItemColor: _muted,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: [
        for (final item in items)
          BottomNavigationBarItem(icon: Icon(item.$1), label: item.$2),
      ],
    );
  }
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter({this.accent = _blue, this.variant = 0});

  final Color accent;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final detail = Paint()
      ..color = accent.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = accent.withValues(alpha: .10);
    final inset = 10.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - 20, size.height - 20);
    canvas.drawRect(rect, stroke);
    final rooms = variant.isEven
        ? [
            Rect.fromLTWH(
              rect.left,
              rect.top,
              rect.width * .48,
              rect.height * .45,
            ),
            Rect.fromLTWH(
              rect.left + rect.width * .52,
              rect.top,
              rect.width * .48,
              rect.height * .45,
            ),
            Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * .5,
              rect.width * .48,
              rect.height * .5,
            ),
            Rect.fromLTWH(
              rect.left + rect.width * .52,
              rect.top + rect.height * .5,
              rect.width * .48,
              rect.height * .5,
            ),
          ]
        : [
            Rect.fromLTWH(
              rect.left,
              rect.top,
              rect.width * .58,
              rect.height * .42,
            ),
            Rect.fromLTWH(
              rect.left + rect.width * .62,
              rect.top,
              rect.width * .38,
              rect.height * .42,
            ),
            Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * .47,
              rect.width * .35,
              rect.height * .53,
            ),
            Rect.fromLTWH(
              rect.left + rect.width * .39,
              rect.top + rect.height * .47,
              rect.width * .61,
              rect.height * .53,
            ),
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
      oldDelegate.accent != accent || oldDelegate.variant != variant;
}
