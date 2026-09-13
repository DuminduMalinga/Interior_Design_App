part of 'main.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload floor plan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bring your space to life',
                style: TextStyle(
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Upload a floor plan and our AI will turn it into a smart, editable design.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 28),
              _UploadDropzone(
                selected: _selected,
                onSelect: () => setState(() => _selected = true),
              ),
              const SizedBox(height: 26),
              const Text(
                'Accepted formats',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Use a clear image, sketch, or scanned document.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 13),
              const _FloorPlanExamples(),
              const SizedBox(height: 28),
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
                    onPressed: _selected
                        ? () => _showProcessingMessage(context)
                        : () => setState(() => _selected = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: Icon(
                      _selected
                          ? Icons.auto_awesome_rounded
                          : Icons.cloud_upload_outlined,
                      size: 20,
                    ),
                    label: Text(
                      _selected ? 'Generate with AI' : 'Upload floor plan',
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

  void _showProcessingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your floor plan is ready for AI processing.'),
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  const _UploadDropzone({required this.selected, required this.onSelect});

  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 268,
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: .10),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _blue.withValues(alpha: .28),
                      _violet.withValues(alpha: .22),
                    ],
                  ),
                  border: Border.all(color: _blue.withValues(alpha: .35)),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.cloud_upload_outlined,
                  color: const Color(0xFFB9D5FF),
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                selected ? 'Floor plan selected' : 'Upload your floor plan',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                selected
                    ? 'Tap below to generate your AI design'
                    : 'Drag and drop or choose an image to begin',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 19),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UploadAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: onSelect,
                  ),
                  const SizedBox(width: 10),
                  _UploadAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onSelect,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadAction extends StatelessWidget {
  const _UploadAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD5E4FF),
        backgroundColor: Colors.white.withValues(alpha: .04),
        side: BorderSide(color: Colors.white.withValues(alpha: .13)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FloorPlanExamples extends StatelessWidget {
  const _FloorPlanExamples();

  @override
  Widget build(BuildContext context) {
    const accents = [_blue, Color(0xFF35C5B5), _violet];
    return Row(
      children: [
        for (var i = 0; i < accents.length; i++) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: ColoredBox(
                  color: const Color(0xFF17202D),
                  child: CustomPaint(
                    painter: _ExamplePlanPainter(
                      accent: accents[i],
                      variant: i,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i < accents.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ExamplePlanPainter extends CustomPainter {
  const _ExamplePlanPainter({required this.accent, required this.variant});

  final Color accent;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final sheet = Rect.fromLTWH(11, 9, size.width - 22, size.height - 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet, const Radius.circular(4)),
      Paint()..color = const Color(0xFFE9EDF3),
    );
    final wall = Paint()
      ..color = const Color(0xFF344253)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final detail = Paint()
      ..color = accent.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = accent.withValues(alpha: .12);
    final rooms = variant == 0
        ? [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 42, 35),
            Rect.fromLTWH(sheet.left + 54, sheet.top + 8, 35, 35),
            Rect.fromLTWH(sheet.left + 8, sheet.top + 47, 31, 42),
            Rect.fromLTWH(sheet.left + 43, sheet.top + 47, 46, 42),
          ]
        : variant == 1
        ? [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 34, 81),
            Rect.fromLTWH(sheet.left + 46, sheet.top + 8, 43, 38),
            Rect.fromLTWH(sheet.left + 46, sheet.top + 50, 43, 39),
          ]
        : [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 81, 28),
            Rect.fromLTWH(sheet.left + 8, sheet.top + 40, 39, 49),
            Rect.fromLTWH(sheet.left + 51, sheet.top + 40, 38, 49),
          ];
    for (var i = 0; i < rooms.length; i++) {
      canvas.drawRect(rooms[i], i == variant ? fill : wall);
      if (i == 0) {
        canvas.drawCircle(rooms[i].center, 5, detail);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExamplePlanPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.variant != variant;
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      );
    final paint = Paint()
      ..color = _blue.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
<<<<<<< Updated upstream
=======

class _LegacyProcessingScreen extends StatefulWidget {
  const _LegacyProcessingScreen();

  @override
  State<_LegacyProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<_LegacyProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _statusTimer;
  Timer? _completeTimer;
  int _statusIndex = 0;

  static const _statuses = [
    'Detecting rooms...',
    'Mapping your floor plan...',
    'Preparing your smart design...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _statusTimer = Timer(const Duration(milliseconds: 1500), _advanceStatus);
    _completeTimer = Timer(
      const Duration(milliseconds: 5400),
      _openRoomSelection,
    );
  }

  void _advanceStatus() {
    if (!mounted) return;
    setState(() => _statusIndex = (_statusIndex + 1) % _statuses.length);
    _statusTimer = Timer(const Duration(milliseconds: 1800), _advanceStatus);
  }

  void _openRoomSelection() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RoomSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _ProcessingBackground(),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
                icon: const Icon(Icons.close_rounded, color: _muted),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 254,
                      height: 254,
                      child: CustomPaint(
                        painter: _ProcessingRingPainter(
                          progress: _controller.value,
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale:
                                1 +
                                (_controller.value < .5
                                        ? _controller.value
                                        : 1 - _controller.value) *
                                    .12,
                            child: const _BlueprintMark(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statuses[_statusIndex],
                        key: ValueKey(_statusIndex),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Our AI is analyzing every detail',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: 165,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: null,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(_blue),
                        ),
                      ),
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

class _ProcessingBackground extends StatelessWidget {
  const _ProcessingBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _ScanlinePainter())),
    );
  }
}

class _ProcessingRingPainter extends CustomPainter {
  const _ProcessingRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .38;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, track);

    final ring = Paint()
      ..shader = const SweepGradient(
        colors: [_blue, _violet, _blue],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 1.45,
      false,
      ring,
    );

    final glow = Paint()
      ..color = _blue.withValues(alpha: .12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius + 2, glow);
  }

  @override
  bool shouldRepaint(covariant _ProcessingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BlueprintMark extends StatelessWidget {
  const _BlueprintMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _surface.withValues(alpha: .95),
        border: Border.all(color: _blue.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: .25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const CustomPaint(painter: _BlueprintPainter()),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF93C5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(27, 26, 50, 51);
    canvas.drawRect(rect, paint);
    canvas.drawLine(
      Offset(rect.left, rect.top + 22),
      Offset(rect.left + 22, rect.top + 22),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + 22, rect.top + 22),
      Offset(rect.left + 22, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + 22, rect.top),
      Offset(rect.left + 22, rect.top + 13),
      paint,
    );
    canvas.drawCircle(Offset(rect.right - 13, rect.bottom - 13), 6, paint);
    canvas.drawCircle(Offset(rect.left + 12, rect.top + 11), 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _blue.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x223E8BFF), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * .8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
>>>>>>> Stashed changes
